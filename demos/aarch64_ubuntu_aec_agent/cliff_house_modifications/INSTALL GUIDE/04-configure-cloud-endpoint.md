# Step 4 — Configure Hermes and the cloud endpoint

Create one isolated Hermes profile and keep its credential outside Git.

## Create the profile

The bootstrap creates:

```text
%LOCALAPPDATA%\hermes\profiles\local-aec-cloud\config.yaml
```

If it does not exist, copy `config/hermes/config.template.yaml` there. Replace:

- `https://REPLACE_WITH_ENDPOINT/v1` with the endpoint base URL.
- `REPLACE_WITH_MODEL_ID` with the exact served model name.
- any unresolved executable or repository path placeholders.

Use `api_mode: chat_completions` for an OpenAI-compatible `/chat/completions` API. If the
provider requires another Hermes API mode, change only that field after checking its docs.

## Store the key

Open `%LOCALAPPDATA%\hermes\.env` in a text editor and add:

```dotenv
AEC_ENDPOINT_API_KEY=replace-with-your-key
```

Do not put the key in `config.yaml`, this repository, screenshots, or support logs.

## Validate the endpoint independently

```powershell
$headers = @{ Authorization = "Bearer $env:AEC_ENDPOINT_API_KEY" }
Invoke-RestMethod -Headers $headers -Uri 'https://YOUR-ENDPOINT/v1/models'
```

Expected result: an HTTP 200 response with a model list. Some providers disable `/models`;
in that case, use their documented health request.

## Confirm there is no DML configuration

```powershell
$profile = "$env:LOCALAPPDATA\hermes\profiles\local-aec-cloud\config.yaml"
Select-String -Path $profile -Pattern 'daystrom|dml|cma|ollama|directml'
```

Expected result: no matches.

## Next step

Continue to [run the Cliff House demo](05-run-cliff-house-demo.md).
