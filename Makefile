.PHONY: all clean test update_cron conda_env


update_cron:
	./scripts/other/update_cron.sh -t $(target)

conda_env:
	conda env create -f envs/$(job).yaml
