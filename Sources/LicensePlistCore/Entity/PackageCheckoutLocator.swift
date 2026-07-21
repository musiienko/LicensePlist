import Foundation

enum PackageCheckoutLocator {
    static func packageDirectory(
        repositoryName: String,
        version: String?,
        revision: String?,
        checkoutPath: URL,
        requiredFileName: String? = nil
    ) -> URL? {
        let repositoryDirectory = checkoutPath.appendingPathComponent(repositoryName)
        guard repositoryDirectory.lp.isExists else {
            return nil
        }

        if let requiredFileName {
            let directFile = repositoryDirectory.appendingPathComponent(requiredFileName)
            if directFile.lp.isExists {
                return repositoryDirectory
            }
        } else if repositoryDirectory.lp.listDir().contains(where: { !$0.lp.isDirectory && !$0.lastPathComponent.hasPrefix(".") }) {
            return repositoryDirectory
        }

        let nestedDirectories = repositoryDirectory.lp.listDir().filter { $0.lp.isDirectory }
        let matchingDirectories = nestedDirectories.filter {
            matchesMetadata(directoryName: $0.lastPathComponent, version: version, revision: revision)
                && containsRequiredFile(in: $0, requiredFileName: requiredFileName)
        }
        if let bestMatch = bestMetadataMatch(from: matchingDirectories, version: version) {
            return bestMatch
        }

        if nestedDirectories.count == 1,
           containsRequiredFile(in: nestedDirectories[0], requiredFileName: requiredFileName) {
            return nestedDirectories[0]
        }

        return nil
    }

    private static func containsRequiredFile(in directory: URL, requiredFileName: String?) -> Bool {
        guard let requiredFileName else {
            return true
        }
        return directory.appendingPathComponent(requiredFileName).lp.isExists
    }

    private static func bestMetadataMatch(from directories: [URL], version: String?) -> URL? {
        guard !directories.isEmpty, let version else {
            return nil
        }

        let sorted = directories.sorted {
            hashSuffixLength(of: $0.lastPathComponent, version: version)
                > hashSuffixLength(of: $1.lastPathComponent, version: version)
        }
        return sorted.first
    }

    private static func hashSuffixLength(of directoryName: String, version: String) -> Int {
        guard directoryName.hasPrefix(version + "-") else {
            return 0
        }
        return directoryName.count - version.count - 1
    }

    private static func matchesMetadata(directoryName: String, version: String?, revision: String?) -> Bool {
        guard let version, let revision else {
            return false
        }

        guard directoryName.hasPrefix(version + "-") else {
            return false
        }

        let suffix = String(directoryName.dropFirst(version.count + 1)).lowercased()
        let revisionLowercased = revision.lowercased()
        return revisionLowercased.hasPrefix(suffix)
    }
}
