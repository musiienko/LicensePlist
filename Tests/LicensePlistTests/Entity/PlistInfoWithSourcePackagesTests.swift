import XCTest
@testable import LicensePlistCore

final class PlistInfoWithSourcePackagesTests: XCTestCase {
    private let github = GitHub(name: "R.swift", nameSpecified: "rswit", owner: "mac-cain13", version: "0.5.4")
    private let sourcePackagesPath = TestUtil.testResourceDir.appendingPathComponent("SourcePackages").lp.fileURL
    private let nestedCheckoutsPath = TestUtil.testResourceDir
        .appendingPathComponent("NestedSourcePackages")
        .lp.fileURL

    func testReadLicenseFromDisk() throws {
        var target = plistInfo()

        XCTAssertNil(target.githubLicenses)
        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)
        XCTAssertEqual(licenses.count, 1)
        let license = licenses.first

        XCTAssertEqual(license?.library, github)
        XCTAssertEqual(license?.body, "license text")
        XCTAssertNil(license?.githubResponse)
    }

    func testReadLicenseMDFromDisk() throws {
        var target = plistInfo(licenseFileNames: ["LICENSE.md"])

        target.loadGitHubLicenses()
        let license = target.githubLicenses?.first

        XCTAssertEqual(license?.body, "license.md text")
    }

    func testReadLicenseWithAsteriskFromDisk() throws {
        var target = plistInfo(licenseFileNames: ["LICENSE.*"])

        target.loadGitHubLicenses()
        let license = target.githubLicenses?.first

        XCTAssertEqual(license?.body, "license.md text")
    }

    func testReadMissedLicenseFromDisk() throws {
        var target = PlistInfo(options: options(licenseFileNames: ["Not-a-license"]))
        target.githubLibraries = [github]

        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)

        XCTAssertTrue(licenses.isEmpty)
    }

    func testReadLicenseFromCustomCheckoutsPath() throws {
        let checkoutsPath = TestUtil.testResourceDir
            .appendingPathComponent("SourcePackages")
            .appendingPathComponent("checkouts")
            .lp.fileURL
        var target = PlistInfo(options: options(
            licenseFileNames: ["LICENSE"],
            packageSourcesPath: nil,
            packageCheckoutsPath: checkoutsPath
        ))
        target.githubLibraries = [github]

        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)

        XCTAssertEqual(licenses.count, 1)
        XCTAssertEqual(licenses.first?.body, "license text")
    }

    func testReadLicenseFromNestedCheckoutsPath() throws {
        var target = PlistInfo(options: options(
            licenseFileNames: ["LICENSE"],
            packageSourcesPath: nil,
            packageCheckoutsPath: nestedCheckoutsPath
        ))
        target.githubLibraries = [github]

        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)

        XCTAssertEqual(licenses.count, 1)
        XCTAssertEqual(licenses.first?.body, "license text\n")
    }

    func testReadLicenseFromNestedCheckoutsPathWithHiddenFileAtRepoRoot() throws {
        let checkoutsPath = TestUtil.testResourceDir
            .appendingPathComponent("NestedSourcePackagesWithHiddenFile")
            .lp.fileURL
        var target = PlistInfo(options: options(
            licenseFileNames: ["LICENSE"],
            packageSourcesPath: nil,
            packageCheckoutsPath: checkoutsPath
        ))
        target.githubLibraries = [github]

        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)

        XCTAssertEqual(licenses.count, 1)
        XCTAssertEqual(licenses.first?.body, "license text\n")
    }

    func testReadLicenseFromNestedCheckoutsPathMatchingVersionAndRevision() throws {
        let github = GitHub(name: "R.swift", nameSpecified: "rswit", owner: "mac-cain13", revision: "18ad905c6f8f0865042e1d1ee4effc7291aa899d", version: "0.5.4")
        let checkoutsPath = TestUtil.testResourceDir
            .appendingPathComponent("NestedSourcePackagesWithMultipleVersions")
            .lp.fileURL
        var target = PlistInfo(options: options(
            licenseFileNames: ["LICENSE"],
            packageSourcesPath: nil,
            packageCheckoutsPath: checkoutsPath
        ))
        target.githubLibraries = [github]

        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)

        XCTAssertEqual(licenses.count, 1)
        XCTAssertEqual(licenses.first?.body, "new license\n")
    }

    func testReadLicensePrefersLongestMatchingRevisionDirectory() throws {
        let github = GitHub(name: "R.swift", nameSpecified: "rswit", owner: "mac-cain13", revision: "18ad905c6f8f0865042e1d1ee4effc7291aa899d", version: "0.5.4")
        let checkoutsPath = TestUtil.testResourceDir
            .appendingPathComponent("NestedSourcePackagesWithDuplicateRevisionPrefixes")
            .lp.fileURL
        var target = PlistInfo(options: options(
            licenseFileNames: ["LICENSE"],
            packageSourcesPath: nil,
            packageCheckoutsPath: checkoutsPath
        ))
        target.githubLibraries = [github]

        target.loadGitHubLicenses()
        let licenses = try XCTUnwrap(target.githubLicenses)

        XCTAssertEqual(licenses.count, 1)
        XCTAssertEqual(licenses.first?.body, "full hash license\n")
    }

    // MARK: Helpers

    private func plistInfo(licenseFileNames: [String] = ["LICENSE"]) -> PlistInfo {
        var target = PlistInfo(options: options(licenseFileNames: licenseFileNames))
        target.githubLibraries = [github]
        return target
    }

    private func options(
        licenseFileNames: [String],
        packageSourcesPath: URL? = nil,
        packageCheckoutsPath: URL? = nil
    ) -> Options {
        return Options(outputPath: URL(fileURLWithPath: "test_result_dir"),
                       cartfilePath: URL(fileURLWithPath: "test_result_dir"),
                       mintfilePath: URL(fileURLWithPath: "test_result_dir"),
                       nestfilePath: URL(fileURLWithPath: "test_result_dir"),
                       podsPath: URL(fileURLWithPath: "test_result_dir"),
                       packagePaths: [URL(fileURLWithPath: "test_result_dir")],
                        packageSourcesPath: packageSourcesPath ?? sourcePackagesPath,
                       packageCheckoutsPath: packageCheckoutsPath,
                       xcworkspacePath: URL(fileURLWithPath: "test_result_dir"),
                       xcodeprojPath: URL(fileURLWithPath: "test_result_dir"),
                       prefix: Consts.prefix,
                       gitHubToken: nil,
                       htmlPath: nil,
                       markdownPath: nil,
                       csvPath: nil,
                       licenseFileNames: licenseFileNames,
                       config: .empty)
    }
}
