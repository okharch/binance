.PHONY: migration

migration:
	@echo "Running migrations..."
	@migrate -path=migrations -database=$$BINANCE_SPOT_DB up