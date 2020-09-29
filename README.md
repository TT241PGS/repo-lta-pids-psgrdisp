# PIDS Display

## Usage

### To start your Phoenix server initially:

- Install dependencies with `mix setup`
- Start pids-data-poller service
- Load env vars with `source .env.dev.sh`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000/display?panel_id=pid0001`](http://localhost:4000/display?panel_id=pid0001) from your browser.

### Subsequent start:

`source .env.dev.sh && iex -S mix phx.server`

### Tests:

`docker-compose down && docker-compose -f docker-compose.test.yaml up -d && sleep 1 && source .env.test.sh && mix test`

## Notes

- Never change the app version and name in mix.exs
- In config/prod.exs, env vars must be used as `"${MY_ENV_VAR}"` instead of `System.get_env("MY_ENV_VAR")`
- `git push` needs tests to pass, so make sure the test database is up before `git push` by executing `docker-compose down && docker-compose -f docker-compose.test.yaml up -d && sleep 1 && source .env.test.sh`

## Deployment

- A push to develop triggers a github action that deploys to nightly
- ECS task definition is at `./task-definitions.json`. Update this file when needed, don't update from AWS console directly except for rollbacks
- Additional env vars should be added to `AWS Parameter Store` and should be referenced in secrets section of `task-definition.json`
