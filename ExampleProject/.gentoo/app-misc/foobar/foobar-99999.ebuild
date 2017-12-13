# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Test Ebuild"
HOMEPAGE="http://example.org"
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS=""
IUSE="reverse"

DEPEND="
	virtual/libc
"
RDEPEND="${DEPEND}"

src_unpack() {
	cp -r -L "$DOTGENTOO_PACKAGE_ROOT" "$S"
}

src_compile() {
	emake $(usex reverse "-DREVERSE" "") foobar
}

src_install() {
	dobin foobar
}
