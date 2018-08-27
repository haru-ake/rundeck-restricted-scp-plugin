# rundeck-restricted-scp-plugin

Restricted file copier plugin via `scp`.

When copying files from the Rundeck server node to the remote node, restrict the copy source file to the following path only.

| Path                                                 | Description                                                            |
|:-----------------------------------------------------|:-----------------------------------------------------------------------|
| `$RUNDECK_BASE/var/tmp/`                             | Path where inline script is placed                                     |
| `$RUNDECK_BASE/var/cache/ScriptURLNodeStepExecutor/` | Where the script retrieved from the URL specified in the job is placed |

