.PHONY: test integration clean deploy destroy

test:
	go test -v -timeout 30m

integration: deploy
	go test -v -timeout 45m -run TestSQLDatabaseConnectivity

deploy:
	terraform init
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

clean:
	go clean -testcache
	rm -f go.sum
	init:
	go mod tidy