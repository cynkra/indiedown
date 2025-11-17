<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# indiedown 0.1.1.9040

## Continuous integration

- Install binaries from r-universe for dev workflow (#81).


# indiedown 0.1.1.9039

## Continuous integration

- Fix reviewdog and add commenting workflow (#80).


# indiedown 0.1.1.9038

## Chore

- Auto-update from GitHub Actions.

  Run: https://github.com/cynkra/indiedown/actions/runs/17450815604

## Continuous integration

- Use workflows for fledge (#79).

- Sync (#78).

- Use reviewdog for external PRs (#77).

- Cleanup and fix macOS (#76).

- Format with air, check detritus, better handling of `extra-packages` (#75).


# indiedown 0.1.1.9037

## Continuous integration

- Enhance permissions for workflow (#74).


# indiedown 0.1.1.9036

## Continuous integration

- Permissions, better tests for missing suggests, lints (#73).


# indiedown 0.1.1.9035

## Continuous integration

- Only fail covr builds if token is given (#72).

- Always use `_R_CHECK_FORCE_SUGGESTS_=false` (#71).


# indiedown 0.1.1.9034

## Continuous integration

- Correct installation of xml2 (#70).


# indiedown 0.1.1.9033

## Chore

- Auto-update from GitHub Actions.

  Run: https://github.com/cynkra/indiedown/actions/runs/14636209573

## Continuous integration

- Explain (#69).

- Add xml2 for covr, print testthat results (#68).

- Fix (#67).

- Sync (#66).


# indiedown 0.1.1.9032

## Continuous integration

- Avoid failure in fledge workflow if no changes (#62).


# indiedown 0.1.1.9031

## Continuous integration

- Fetch tags for fledge workflow to avoid unnecessary NEWS entries (#61).


# indiedown 0.1.1.9030

## Continuous integration

- Use larger retry count for lock-threads workflow (#60).


# indiedown 0.1.1.9029

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#59).


# indiedown 0.1.1.9028

## Continuous integration

- Explicit permissions (#58).


# indiedown 0.1.1.9027

## Continuous integration

- Use styler from main branch (#57).


# indiedown 0.1.1.9026

## Continuous integration

- Need to install R on Ubuntu 24.04 (#56).

- Use Ubuntu 24.04 and styler PR (#54).

## Uncategorized

- PLACEHOLDER https://github.com/cynkra/indiedown/pull/16 (#16).


# indiedown 0.1.1.9025

## Continuous integration

  - Correctly detect branch protection (#53).


# indiedown 0.1.1.9024

## Continuous integration

  - Use stable pak (#52).


# indiedown 0.1.1.9023

## Continuous integration

  - Trigger run (#51).
    
      - ci: Trigger run
    
      - ci: Latest changes


# indiedown 0.1.1.9022

## Continuous integration

  - Use pkgdown branch (#50).
    
      - ci: Use pkgdown branch
    
      - ci: Updates from duckdb
    
      - ci: Trigger run


# indiedown 0.1.1.9021

## Continuous integration

  - Install via R CMD INSTALL ., not pak (#49).
    
      - ci: Install via R CMD INSTALL ., not pak
    
      - ci: Bump version of upload-artifact action


# indiedown 0.1.1.9020

## Continuous integration

  - Install local package for pkgdown builds.

  - Improve support for protected branches with fledge.

  - Improve support for protected branches, without fledge.


# indiedown 0.1.1.9019

## Chore

- Auto-update from GitHub Actions.

  Run: https://github.com/cynkra/indiedown/actions/runs/10425483323

## Continuous integration

- Sync with latest developments.


# indiedown 0.1.1.9018

## Continuous integration

- Use v2 instead of master.


# indiedown 0.1.1.9017

## Continuous integration

- Inline action.


# indiedown 0.1.1.9016

## Chore

- Auto-update from GitHub Actions.

  Run: https://github.com/cynkra/indiedown/actions/runs/10207825578

## Continuous integration

- Use dev roxygen2 and decor.


# indiedown 0.1.1.9015

## Continuous integration

- Fix on Windows, tweak lock workflow.


# indiedown 0.1.1.9014

## Chore

- Auto-update from GitHub Actions.

  Run: https://github.com/cynkra/indiedown/actions/runs/9727973619


# indiedown 0.1.1.9013

## Chore

- Auto-update from GitHub Actions.

  Run: https://github.com/cynkra/indiedown/actions/runs/9692290881

## Continuous integration

- Avoid checking bashisms on Windows.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.


# indiedown 0.1.1.9012

## Documentation

- Fix url (#28).


# indiedown 0.1.1.9011

## Chore

### deps

- Update peter-evans/create-pull-request action to v6.


# indiedown 0.1.1.9010

## Chore

### deps

- Update nick-fields/retry action to v3.


# indiedown 0.1.1.9009

## Chore

### deps

- Update dessant/lock-threads action to v5.

### deps

- Update actions/cache action to v4.

## Documentation

- Set BS version explicitly for now.

  https://github.com/cynkra/cynkratemplate/issues/53


# indiedown 0.1.1.9008

- Internal changes only.


# indiedown 0.1.1.9007

- Internal changes only.


# indiedown 0.1.1.9006

- Merge pull request #39 from cynkra/snapshot-main-rcc-smoke-null.


# indiedown 0.1.1.9005

## Chore

- Build-ignore `renovate.json`.

## Uncategorized

- Merge pull request #30 from cynkra/renovate/configure.

  Configure Renovate


# indiedown 0.1.1.9004

- Internal changes only.


# indiedown 0.1.1.9003

- Internal changes only.


# indiedown 0.1.1.9002

## Chore

- Avoid tests on R \< 4.0 on GHA.


# indiedown 0.1.1.9001

- Internal changes only.


# indiedown 0.1.1.9000

## simplify

- Substitute <<>> in the template.

## Uncategorized

- Harmonize yaml formatting.

- Revert changes to matrix section.

- Merge pull request #27 from cynkra/f-backto-cleveref.

Back to cleveref

- Merge pull request #26 from cynkra/b-cleveref.

Comment out cleveref since not used actively

- Merge pull request #25 from cynkra/tidyout.

removed tidyverse library call 

- Merge pull request #17 from cynkra/b-workflow-2.



- Merge pull request #15 from cynkra/b-workflows.



- Reduce parallelism.

- Also check dev on cran-* branches.

- Update hash key for dev.

- Remove R 3.3.

- Merge pull request #14 from cynkra/dr_down.

Dr down

- Merge pull request #1 from christophsax/more-pandoc.

More pandoc


# indiedown 0.1.1

- CRAN feedback: better DESCRIPTION, extended documentation, examples.

# indiedown 0.1.0

Initial release.

- `create_indiedown_package()` creates a ready-to-customize R Markdown template package.
- `use_indiedown_gfonts()` adds Google fonts to a template package.
