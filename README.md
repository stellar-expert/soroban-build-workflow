# Soroban Smart Contract Compilation Workflow

Reusable GitHub Actions workflow that streamlines the compilation and release process of Stellar smart contracts for Soroban WASM runtime.

When triggered, this workflow:
- Compiles a smart contract (or multiple contracts) in the repository
- Creates an optimized WebAssembly file ready to be deployed to Soroban
- Publishes GitHub release with attached build artifacts
- Includes SHA256 hashes of complied WASM files into actions output for further verification

## Configuration

### Prerequisites

- Create a GitHub Actions workflow file `.github/workflows/release.yml` in your repository.
- Decide how the compliation workflow will be triggered. The recommended way is to configure workflow activation on git tag creation. This should simplify versioning and ensure unique release names.

### Workflow inputs and secrets

Basic compilation workflow path:  
`stellar-expert/soroban-build-workflow/.github/workflows/release.yml@main`

The workflow expects the following inputs in the `with` section:
- `release_name` (required) - release name template that includes a release version variable, e.g. `${{ github.ref_name }}`
- `package` (optional) - package name to build. Builds contract in working directory by default
- `relative_path` (optional) - relative path to the contract source directory. Defaults to the repository root directory
- `make_target` (optional) - make target to invoke. Not invoked by default. Useful for contracts with dependencies, that must be built before the main contract

### Basic workflow for the reporisotry with a single contract

```yaml
name: Build and Release  # name it whatever you like
on:
  push: 
    tags:
      - 'v*'  # triggered whenever a new tag (previxed with "v") is pushed to the repository
jobs:
  release-contract-a:
    uses: stellar-expert/soroban-build-workflow/.github/workflows/release.yml@main
    with:
      release_name: ${{ github.ref_name }}          # use git tag as unique release name
      release_description: 'Contract release'       # some boring placeholder text to attach
      relative_path: '["src/my-awesome-contract"]'  # relative path to your really awesome contract
      package: 'my-awesome-contract'                # package name to build
      make_target: 'build-dependencies'             # make target to invoke
    secrets:  # the authentication token will be automatically created by GitHub
      release_token: ${{ secrets.GITHUB_TOKEN }}    # don't modify this line
```

### Building multiple contracts

To build multiple contracts, add a separate job for each contract. The workflow will compile and release each contract independently.

```yaml
name: Build and Release  # name it whatever you like
on:
  push: 
    tags:
      - 'v*'  # triggered whenever a new tag (previxed with "v") is pushed to the repository
jobs:
  release-contract-a:
    uses: stellar-expert/soroban-build-workflow/.github/workflows/release.yml@main
    with:
      release_name: ${{ github.ref_name }}          
      release_description: 'Awesome contract release'       
      relative_path: '["src/my-awesome-contract"]'  
      package: 'my-awesome-contract'                
      make_target: 'build-dependencies'             
    secrets:
      release_token: ${{ secrets.GITHUB_TOKEN }}
  
  release-contract-b:
    uses: stellar-expert/soroban-build-workflow/.github/workflows/release.yml@main
    with:
      release_name: ${{ github.ref_name }}          
      release_description: 'Contract release'
      relative_path: '["src/another-awesome-contract"]'
    secrets:
      release_token: ${{ secrets.GITHUB_TOKEN }}
  
  
  release-contract-from-root:
    uses: stellar-expert/soroban-build-workflow/.github/workflows/release.yml@main
    with:
      release_name: ${{ github.ref_name }}          
      release_description: 'Root contract release'
    secrets:
      release_token: ${{ secrets.GITHUB_TOKEN }}
```

### Triggering build process manually

Triggering this workflow manually requires a unique release name prompt. Replace the trigger condition in config
and update `release_name` to utilize the value from the prompt.

```yaml
on:
  workflow_dispatch:
    inputs:
      release_name:
        description: 'Unique release name'
        required: true
        type: string
jobs:
  release-contract:
    with:
      release_name: ${{ github.event.inputs.release_name }}
```

## Notes

- The workflow assumes that each contract directory contains the necessary structure and files for your build process.
- If you want to run your contract tests automatically before deploying the contract, add corresponding action invocation
  before the `release_contract` job to make sure that broken contracts won't end up in published releases.
- In case of the multi-contract repository setup, contracts shouldn't have the same name (defined in TOML file) and version
  to avoid conflicts during the release process.
- To enable automatic contract source validation process, contracts should be deployed to Stellar Network directly
  from a complied GitHub realese generated by this workflow. Otherwise the deployed contract hash may not
  match the release artifcats due to the compilation environment variations.
