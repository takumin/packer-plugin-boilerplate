package main

import (
	"fmt"
	"os"

	"github.com/hashicorp/packer-plugin-sdk/plugin"

	"github.com/takumin/packer-plugin-boilerplate/version"
)

func main() {
	pps := plugin.NewSet()
	// pps.RegisterBuilder(plugin.DEFAULT_NAME, new(builder.Builder))
	// pps.RegisterProvisioner(plugin.DEFAULT_NAME, new(provisioner.Provisioner))
	// pps.RegisterPostProcessor(plugin.DEFAULT_NAME, new(post_processor.PostProcessor))
	// pps.RegisterDatasource(plugin.DEFAULT_NAME, new(datasource.Datasource))
	pps.SetVersion(version.PluginVersion)
	err := pps.Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
