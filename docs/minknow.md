# MinKNOW

## User configuration

### Save pod5 by default
MinKNOW released a major update (Tested 25.09.16) that changes the default sequencing run behavior to not store pod5 files. This is dangerous for our setup as we cannot basecall in realtime so we risk losing our data should this setting not be changed manually before a run.

> [!NOTE]
> The following documentation was provided by ONT support.

To enable the setting by default you will need to create, add, and run with configuration `json` file.

Create the file run_config.json with the following content and save it:
```bash
configfile="home/prom/.config/minknow/run_config.json"
[[ ! -f "${configfile}" ]] && echo "File does not exist."
echo '{"pod5Enabled": true}' > /home/prom/.config/minknow/run_config.json
```

Then set read permissions.
```bash
chmod +r "${configfile}"
```

Open `MinKNOW` and then:
1. `Start`
2. `Start Sequencing`
3. Fill information in `1. Positions` tab and continue to `2. Kit`
4. Once `Kit` is chosen, a note should appear at the bottom of the screen: "Default run settings have been applied from the file `/home/prom/.config/minknow/run_config.json`".
5. Confirm in the `Output` section that `Raw reads` lists `POD5`

### Change hostname
The migration to Ubuntu Focal caused the hostname of the PromethION to change. In our case, changing from `PCAMP249` to `249` causes issues with MinKNOW's basecalling with Slurm.

```bash
sudo -Si
hostnamectl hostname "${new_hostname}"
# Update host files.
/opt/ont/platform/bin/ont-update-hosts-file
```

After the change has been made, please run the following commands to ensure the hostname is changed correctly.
```bash
hostname
cat /etc/hosts
```
