load("@container_structure_test//:defs.bzl", "container_structure_test")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_image_index")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

NODEJS_MAJOR_VERSIONS = ("20", "22", "24")

DEBUG_MODE = ["", "_debug"]
USERS = ["root", "nonroot"]

def nodejs_image_index(distro, major_version, architectures):
    """nodejs image index for a distro

    Args:
        distro: name of distribution
        major_version: version of nodejs
        architectures: all architectures included in index
    """
    [
        oci_image_index(
            name = "nodejs" + major_version + mode + "_" + user + "_" + distro,
            images = [
                "nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro
                for arch in architectures
            ],
        )
        for mode in DEBUG_MODE
        for user in USERS
    ]

def _check_certificates_tar():
    # only create once
    if native.existing_rule("check_certificate"):
        return

    pkg_tar(
        name = "check_certificate",
        srcs = ["testdata/check_certificate.js"],
    )

def nodejs_image(distro, major_version, arch):
    """nodejs and debug image with tests

    Args:
        distro: name of distribution
        major_version: version of nodejs
        arch: the target arch
    """
    [
        oci_image(
            name = "nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro,
            base = "//cc:cc" + mode + "_" + user + "_" + arch + "_" + distro,
            entrypoint = ["/nodejs/bin/node"],
            tars = [
                "@nodejs" + major_version + "_" + arch,
            ],
        )
        for mode in DEBUG_MODE
        for user in USERS
    ]

    _check_certificates_tar()

    [
        container_structure_test(
            name = "nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro + "_test",
            configs = [
                "testdata/nodejs" + major_version + ".yaml",
                "testdata/check_headers.yaml",
                "testdata/check_npm.yaml",
            ],
            image = "nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro,
            tags = [
                arch,
                "manual",
            ],
        )
        for mode in DEBUG_MODE
        for user in USERS
    ]

    [
        oci_image(
            name = "check_certificate_nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro,
            base = "nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro,
            tars = [
                ":check_certificate",
            ],
        )
        for mode in DEBUG_MODE
        for user in USERS
    ]

    [
        container_structure_test(
            name = "check_certificate_nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro + "_test",
            configs = ["testdata/check_certificate.yaml"],
            image = "check_certificate_nodejs" + major_version + mode + "_" + user + "_" + arch + "_" + distro,
            tags = [
                arch,
                "manual",
            ],
        )
        for mode in DEBUG_MODE
        for user in USERS
    ]
