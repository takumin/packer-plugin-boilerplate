//go:generate packer-sdc mapstructure-to-hcl2 -type Config

package example

import (
	"github.com/hashicorp/packer-plugin-sdk/common"
)

type Config struct {
	common.PackerConfig `mapstructure:",squash"`
	URL                 string `mapstructure:"url" required:"true"`
}
