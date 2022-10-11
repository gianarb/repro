Build with 

```
nixos-rebuild build-vm --impure --flake .#snowflake
```

Verify if it works:

```
./result/bin/run-nixos-vm
```

Check with `ps aux | grep pixiecore` if it has a `cmdline` set we are good
