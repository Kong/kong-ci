## Kong CI tooling

Single place for scripts used in Kong repositories for CI needs.

## Reference

- `setup_env.sh`: set up a basic environment, with OpenResty, Cassandra, 
and Redis. Used in Kong & Kong plugins CI.

- `setup_plugin_env.sh`: sets up a Kong installation (per `setup_env.sh` above),
installs the plugin, and generates the test commands to test a plugin.

    - requires a `rockspec` file in the root-dir to install the plugin
    - commands generated are `$LUACHECK_CMD` (linter) and `$BUSTED_CMD` (test
    execution)
    - example: see [the canary plugin](https://github.com/Kong/kong-plugin-enterprise-canary/blob/master/.travis.yml)
