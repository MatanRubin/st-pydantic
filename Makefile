PACKAGE_NAME := st_pydantic
PROJECT_NAME := st-pydantic

ifeq ($(OS), Windows_NT)
  MV = move /f
  RM = del /F /Q
  TOUCH = type nul >
  PACKAGE_VERSION_STR ?= "$(PACKAGE_VERSION)"
else
  MV = mv -f
  RM = rm -rf
  TOUCH = touch
  PACKAGE_VERSION_STR ?= "\"$(PACKAGE_VERSION)\""
endif

# . . . . . . . . . . . . Phony Targets . . . . . . . . . . . . . . . .
.PHONY: help all clean bootstrap check test coverage format ruff mypy package prune docs

help:
	@# Magic line used to create self-documenting makefiles.
	@# See https://stackoverflow.com/a/35730928
	@awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' Makefile | column -s: -t

# Build the API documentation.
docs:
	poetry run lazydocs --overview-file=README.md --src-base-url=https://github.com/matanrubin/st-pydantic/blob/main st_pydantic

all: check test

check: bootstrap
	poetry run pre-commit run --all-files
	# TODO add pydocstyle

test: bootstrap
	poetry run pytest \
		--log-cli-level=4 \
		-m 'not cicd_pipeline_skip' \
		--junit-xml $(or $(JUNIT_REPORT), "build/junit-report.xml") \
		--cov=. \
		--cov-fail-under=$(or $(COVERAGE_FAIL_UNDER), 70) \
		--cov-report="xml:$(or $(COVERAGE_REPORT), build/coverage.xml)" \
		tests

coverage: bootstrap
	poetry run pytest -m 'not cicd_pipeline_skip' --cov-report html --cov-report term --cov=. --log-cli-level=4 tests

ruff: bootstrap
	poetry run ruff check --fix .

format: bootstrap
	poetry run ruff format .

mypy: bootstrap
	poetry run mypy -p $(PACKAGE_NAME) -p tests

package: check test
	poetry build

bootstrap: .make.bootstrap

prune:
	$(RM) -rf .make.bootstrap
	$(RM) -rf .venv

# . . . . . Real Targets . . . . .

# We need to reinstall dependencies whenever pyproject.toml is newer than the
# lock file than the one created the last time we bootstrapped.
# We can't use the committed lock file, as it is committed to git and when
# someone pulls it from git it will always seem up to date.
.make.bootstrap: pyproject.toml
	poetry install
	$(TOUCH) .make.bootstrap
