# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

EGO_SUM=(
	"github.com/davecgh/go-spew v1.1.0/go.mod"
	"github.com/davecgh/go-spew v1.1.1"
	"github.com/davecgh/go-spew v1.1.1/go.mod"
	"github.com/dustin/go-humanize v1.0.1"
	"github.com/dustin/go-humanize v1.0.1/go.mod"
	"github.com/hebcal/gematriya v1.0.1"
	"github.com/hebcal/gematriya v1.0.1/go.mod"
	"github.com/hebcal/greg v1.0.2"
	"github.com/hebcal/greg v1.0.2/go.mod"
	"github.com/hebcal/hdate v1.2.0"
	"github.com/hebcal/hdate v1.2.0/go.mod"
	"github.com/hebcal/hebcal-go v0.10.5"
	"github.com/hebcal/hebcal-go v0.10.5/go.mod"
	"github.com/nathan-osman/go-sunrise v1.1.0"
	"github.com/nathan-osman/go-sunrise v1.1.0/go.mod"
	"github.com/pborman/getopt/v2 v2.1.0"
	"github.com/pborman/getopt/v2 v2.1.0/go.mod"
	"github.com/pmezard/go-difflib v1.0.0"
	"github.com/pmezard/go-difflib v1.0.0/go.mod"
	"github.com/stretchr/objx v0.1.0/go.mod"
	"github.com/stretchr/objx v0.4.0/go.mod"
	"github.com/stretchr/objx v0.5.0/go.mod"
	"github.com/stretchr/objx v0.5.2/go.mod"
	"github.com/stretchr/testify v1.7.1/go.mod"
	"github.com/stretchr/testify v1.8.0/go.mod"
	"github.com/stretchr/testify v1.8.1/go.mod"
	"github.com/stretchr/testify v1.8.4/go.mod"
	"github.com/stretchr/testify v1.10.0"
	"github.com/stretchr/testify v1.10.0/go.mod"
	"gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405"
	"gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod"
	"gopkg.in/yaml.v3 v3.0.0-20200313102051-9f266ea9e77c/go.mod"
	"gopkg.in/yaml.v3 v3.0.1"
	"gopkg.in/yaml.v3 v3.0.1/go.mod"
)

DESCRIPTION="Perpetual Jewish Calendar"
HOMEPAGE="https://github.com/hebcal/hebcal"
SRC_URI="https://github.com/hebcal/hebcal/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.13"
RDEPEND=""

src_compile() {
	ego build -o hebcal
}

src_install() {
	dobin hebcal
	doman hebcal.1
	dodoc README.md
}
