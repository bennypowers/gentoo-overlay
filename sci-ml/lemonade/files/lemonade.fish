# Fish completions for lemonade CLI

# Disable file completions by default
complete -c lemonade -f

# Global options
complete -c lemonade -l host -d 'Server host' -r
complete -c lemonade -l port -d 'Server port' -r
complete -c lemonade -l api-key -d 'API key for authentication' -r
complete -c lemonade -s h -l help -d 'Display help information'
complete -c lemonade -l help-all -d 'Display help for all subcommands'
complete -c lemonade -s v -l version -d 'Display version'

# Backend options shared by run, launch, load
set -l __lemonade_backend_cmds run launch load
for cmd in $__lemonade_backend_cmds
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l ctx-size -d 'Context size for model' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l llamacpp -d 'LlamaCpp backend' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l llamacpp-args -d 'Args for llama-server' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l flm-args -d 'Args for flm serve' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l sdcpp -d 'SD.cpp backend' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l sdcpp-args -d 'Args for sd-server' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l vllm -d 'vLLM backend' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l vllm-args -d 'Args for vllm-server' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l whispercpp -d 'WhisperCpp backend' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l whispercpp-args -d 'Args for whisper-server' -r
    complete -c lemonade -n "__fish_seen_subcommand_from $cmd" -l save-options -d 'Save model options for future use'
end

# Subcommands
complete -c lemonade -n __fish_use_subcommand -a run -d 'Load model and open webapp'
complete -c lemonade -n __fish_use_subcommand -a launch -d 'Launch agent with model'
complete -c lemonade -n __fish_use_subcommand -a backends -d 'List recipes and backends'
complete -c lemonade -n __fish_use_subcommand -a recipes -d 'List recipes and backends'
complete -c lemonade -n __fish_use_subcommand -a status -d 'Check server status'
complete -c lemonade -n __fish_use_subcommand -a logs -d 'Open server logs in web UI'
complete -c lemonade -n __fish_use_subcommand -a scan -d 'Scan for network beacons'
complete -c lemonade -n __fish_use_subcommand -a config -d 'View or modify server config'
complete -c lemonade -n __fish_use_subcommand -a list -d 'List available models'
complete -c lemonade -n __fish_use_subcommand -a pull -d 'Pull/download a model'
complete -c lemonade -n __fish_use_subcommand -a delete -d 'Delete a model'
complete -c lemonade -n __fish_use_subcommand -a load -d 'Load a model'
complete -c lemonade -n __fish_use_subcommand -a unload -d 'Unload a model'
complete -c lemonade -n __fish_use_subcommand -a import -d 'Import model from JSON'
complete -c lemonade -n __fish_use_subcommand -a export -d 'Export model info to JSON'
complete -c lemonade -n __fish_use_subcommand -a cleanup-cache -d 'Clean orphaned HF cache files'

# launch
complete -c lemonade -n "__fish_seen_subcommand_from launch" -s m -l model -d 'Model name to load' -r
complete -c lemonade -n "__fish_seen_subcommand_from launch" -s p -l provider -d 'Model provider name' -r
complete -c lemonade -n "__fish_seen_subcommand_from launch" -l directory -d 'Remote recipe directory' -r
complete -c lemonade -n "__fish_seen_subcommand_from launch" -l recipe-file -d 'Remote recipe JSON filename' -r
complete -c lemonade -n "__fish_seen_subcommand_from launch" -l agent-args -d 'Args for agent process' -r
complete -c lemonade -n "__fish_seen_subcommand_from launch; and not __fish_seen_subcommand_from claude codex opencode" -a 'claude codex opencode' -d 'Agent'

# backends/recipes subcommands
complete -c lemonade -n "__fish_seen_subcommand_from backends recipes" -a install -d 'Install a backend'
complete -c lemonade -n "__fish_seen_subcommand_from backends recipes" -a uninstall -d 'Uninstall a backend'

# status
complete -c lemonade -n "__fish_seen_subcommand_from status" -l json -d 'Output as JSON'

# scan
complete -c lemonade -n "__fish_seen_subcommand_from scan" -l duration -d 'Scan duration in seconds' -r

# config subcommands
complete -c lemonade -n "__fish_seen_subcommand_from config" -a set -d 'Set config values'

# list
complete -c lemonade -n "__fish_seen_subcommand_from list" -l downloaded -d 'Show only downloaded models'

# pull
complete -c lemonade -n "__fish_seen_subcommand_from pull" -l checkpoint -d 'TYPE CHECKPOINT pair for custom model' -r
complete -c lemonade -n "__fish_seen_subcommand_from pull" -l recipe -d 'Recipe for custom model' -r
complete -c lemonade -n "__fish_seen_subcommand_from pull" -l label -d 'Label for custom model' -ra 'appear-builtin coding embeddings hot reasoning reranking tool-calling vision'

# import
complete -c lemonade -n "__fish_seen_subcommand_from import" -l directory -d 'Remote recipe directory' -r
complete -c lemonade -n "__fish_seen_subcommand_from import" -l recipe-file -d 'Remote recipe JSON filename' -r
complete -c lemonade -n "__fish_seen_subcommand_from import" -l skip-prompt -d 'Run non-interactively'
complete -c lemonade -n "__fish_seen_subcommand_from import" -l yes -d 'Alias for --skip-prompt'
complete -c lemonade -n "__fish_seen_subcommand_from import" -F

# export
complete -c lemonade -n "__fish_seen_subcommand_from export" -l output -d 'Output file path' -rF

# cleanup-cache
complete -c lemonade -n "__fish_seen_subcommand_from cleanup-cache" -l dry-run -d 'Preview without deleting'
