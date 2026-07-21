//
//  SwiftPackage.swift
//  LicensePlistCore
//
//  Created by Matthias Buchetics on 20.09.19.
//

import Foundation

public struct SwiftPackage: Equatable {
    let package: String
    let repositoryURL: String
    let revision: String?
    let version: String?
    let packageDefinitionVersion: Int
}

struct SwiftPackageV1: Decodable {
    struct State: Decodable {
        let branch: String?
        let revision: String?
        let version: String?
    }

    let package: String
    let repositoryURL: String
    let state: State
}

struct ResolvedPackagesV1: Decodable {
    struct Pins: Decodable {
        let pins: [SwiftPackageV1]
    }

    let object: Pins
    let version: Int
}

struct SwiftPackageV2: Decodable {
    struct State: Decodable {
        let branch: String?
        let revision: String?
        let version: String?
    }

    let identity: String
    let location: String
    let state: State
}

struct ResolvedPackagesV2: Decodable {
    let pins: [SwiftPackageV2]
    let version: Int
}

extension SwiftPackage {
    struct PreferredRepositoryReference: Equatable {
        let owner: String
        let name: String
    }

    var repositoryIdentifier: String? {
        Self.repositoryIdentifier(from: repositoryURL)
    }

    static func loadPackages(_ content: String) -> [SwiftPackage] {
        guard let data = content.data(using: .utf8) else { return [] }
        if let resolvedPackagesV1 = try? JSONDecoder().decode(ResolvedPackagesV1.self, from: data) {
            return resolvedPackagesV1.object.pins.map {
                SwiftPackage(package: $0.package, repositoryURL: $0.repositoryURL, revision: $0.state.revision, version: $0.state.version, packageDefinitionVersion: 1)
            }
        } else if let resolvedPackagesV2 = try? JSONDecoder().decode(ResolvedPackagesV2.self, from: data) {
            return resolvedPackagesV2.pins.map {
                SwiftPackage(package: $0.identity, repositoryURL: $0.location, revision: $0.state.revision, version: $0.state.version, packageDefinitionVersion: 2)
            }
        } else {
            return []
        }
    }

    static func preferredDependencyNames(from packageManifest: String) -> [String: String] {
        preferredDependencyReferences(from: packageManifest).mapValues { $0.name }
    }

    static func preferredDependencyReferences(from packageManifest: String) -> [String: PreferredRepositoryReference] {
        let pattern = #"\.package\s*\(\s*url\s*:\s*"([^"]+)""#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsPackageManifest = packageManifest as NSString
        let matches = regex.matches(in: packageManifest,
                                    options: [],
                                    range: NSRange(location: 0, length: nsPackageManifest.length))
        return matches.reduce(into: [String: PreferredRepositoryReference]()) { result, match in
            let repositoryURL = nsPackageManifest.substring(with: match.range(at: 1))
            guard let repositoryIdentifier = repositoryIdentifier(from: repositoryURL),
                  let repositoryName = repositoryName(from: repositoryURL),
                  let repositoryOwner = repositoryOwner(from: repositoryURL) else { return }
            result[repositoryIdentifier] = PreferredRepositoryReference(owner: repositoryOwner, name: repositoryName)
        }
    }

    func toGitHub(
        renames: [String: String],
        checkoutPath: URL? = nil,
        preferredRepositoryReference: PreferredRepositoryReference? = nil
    ) -> GitHub? {
        guard repositoryURL.contains("github.com"),
              let repositoryName = Self.repositoryName(from: repositoryURL),
              let owner = Self.repositoryOwner(from: repositoryURL) else { return nil }

        let resolvedName = getDefaultName(for: owner, and: repositoryName, checkoutPath: checkoutPath)
        let canonicalRepositoryName = preferredRepositoryReference?.name
            ?? canonicalRepositoryName(fromResolvedName: resolvedName, repositoryName: repositoryName)
            ?? repositoryName
        let canonicalOwner = preferredRepositoryReference?.owner ?? owner

        let nameSpecified = renames[canonicalRepositoryName]
            ?? renames[repositoryName]
            ?? resolvedName

        return GitHub(name: canonicalRepositoryName,
                      nameSpecified: nameSpecified,
                      owner: canonicalOwner,
                      revision: revision,
                      version: version)
    }

    private func getDefaultName(for owner: String, and name: String, checkoutPath: URL?) -> String {
        guard packageDefinitionVersion != 1 else { return package } // In SPM v1 the Package.resolved JSON always contains the correct name, no need for anything else.
        guard let packageDefinition = packageDefinition(for: owner, name: name, checkoutPath: checkoutPath) else { return fallbackName(using: name) }
        return parseName(from: packageDefinition) ?? fallbackName(using: name)
    }

    private func packageDefinition(for owner: String, name: String, checkoutPath: URL?) -> String? {
        // Try to read from a checkout directory in checkout folder
        let packageDefinitionFromDisk = checkoutPath.map { readPackageDefinition(name: name, checkoutPath: $0) }
        // Then download the definition from Github as a fallback
        return packageDefinitionFromDisk ?? loadPackageDefinitionFromGithub(for: owner, name: name)
    }

    private func readPackageDefinition(name: String, checkoutPath: URL) -> String? {
        let packageDirectory = packageDirectory(name: name, checkoutPath: checkoutPath)
        let url = packageDirectory?.appendingPathComponent("Package.swift")
        guard let url else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func packageDirectory(name: String, checkoutPath: URL) -> URL? {
        PackageCheckoutLocator.packageDirectory(
            repositoryName: name,
            version: version,
            revision: revision,
            checkoutPath: checkoutPath,
            requiredFileName: "Package.swift"
        )
    }

    private func loadPackageDefinitionFromGithub(for owner: String, name: String) -> String? {
        guard let version = version else { return nil }
        guard let packageDefinitionURL = URL(string: "https://raw.githubusercontent.com/\(owner)/\(name)/\(version)/Package.swift") else { return nil }
        return try? String(contentsOf: packageDefinitionURL, encoding: .utf8)
    }

    private func fallbackName(using githubName: String) -> String {
        packageDefinitionVersion == 1 ? package : githubName
    }

    private func canonicalRepositoryName(fromResolvedName resolvedName: String, repositoryName: String) -> String? {
        guard resolvedName.caseInsensitiveCompare(repositoryName) == .orderedSame else {
            return nil
        }
        return resolvedName
    }

    private static func repositoryOwner(from repositoryURL: String) -> String? {
        let urlParts = normalizedURLParts(from: repositoryURL)
        if urlParts.count >= 3 {
            return urlParts[urlParts.count - 2]
        }
        return urlParts.first?.components(separatedBy: ":").last
    }

    private static func repositoryName(from repositoryURL: String) -> String? {
        normalizedURLParts(from: repositoryURL).last?.deletingSuffix(".git")
    }

    private static func repositoryIdentifier(from repositoryURL: String) -> String? {
        guard let owner = repositoryOwner(from: repositoryURL)?.lowercased(),
              let name = repositoryName(from: repositoryURL)?.lowercased() else { return nil }
        return "\(owner)/\(name)"
    }

    private static func normalizedURLParts(from repositoryURL: String) -> [String] {
        repositoryURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .deletingSuffix("/")
            .components(separatedBy: "/")
    }

    func parseName(from packageDefinition: String) -> String? {
        // Step 1 - Trim the beginning of the Package Description to where the Package object is starting to be defined -> return as a one-liner without spaces
        let startingPoint = packageDefinition
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .components(separatedBy: "let package = Package").element(at: 1)
        guard !startingPoint.isEmpty else { return nil }

        // Step 2 - Assemble Reduced Package Description
        // This removes all nested square brackets and everything written after the closing round bracket of the Package definition
        var nestingRoundBracketsCounter = 0
        var nestingSquareBracketsCounter = 0
        var reducedPackageDescription = ""

        parsing: for character in startingPoint {
            switch character {
            case "(":
                nestingRoundBracketsCounter += 1
                reducedPackageDescription.append(nestingSquareBracketsCounter == 0 ? "\(character)" : "")

            case ")":
                nestingRoundBracketsCounter -= 1
                reducedPackageDescription.append(nestingSquareBracketsCounter == 0 ? "\(character)" : "")
                if nestingRoundBracketsCounter < 1 {
                    break parsing
                }

            case "[":
                nestingSquareBracketsCounter += 1

            case "]":
                nestingSquareBracketsCounter -= 1

            default:
                reducedPackageDescription.append(nestingSquareBracketsCounter == 0 ? "\(character)" : "")
            }
        }

        // Step 3 - Retrieve name from the reduced Package Description
        // We can now be confident that we only have the top level description which has exactly one name.

        let name = reducedPackageDescription
            .replacingOccurrences(of: "name\\s?:\\s?\"", with: "name:\"", options: .regularExpression)
            .components(separatedBy: "name:\"")
            .element(at: 1)
            .components(separatedBy: "\"")
            .element(at: 0)

        return name.isEmpty ? nil : name
    }

}

extension Array where Element == String {

    func element(at index: Int) -> String {
        guard (0 ..< count).contains(index) else { return "" }
        return String(self[index])
    }

}
