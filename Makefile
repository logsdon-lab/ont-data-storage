.PHONY: all clean test update_cron


update_cron:
	./scripts/other/update_cron.sh -t $(target)
