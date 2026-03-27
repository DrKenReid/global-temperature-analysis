# Contributing to Global Temperature Analysis

Thanks for your interest! Here's how to help.

## Ways to Contribute

- **Report bugs**: Data pipeline issues, broken queries, or visualization errors.
- **Suggest improvements**: New datasets, additional analyses, or better visualizations.
- **Fix issues**: Check the [Issues](https://github.com/DrKenReid/global-temperature-analysis/issues) tab.
- **Improve docs**: Clarify methodology, fix typos, add references.

## Project Structure

| Directory | What it contains |
|-----------|-----------------|
| `R/` | R scripts for data processing and analysis |
| `sql/` | SQL Server queries |
| `data/` | Raw and processed datasets |
| `docs/` | Documentation and references |

## Setup

`ash
git clone https://github.com/DrKenReid/global-temperature-analysis.git
`

**Requirements:**
- R (with relevant packages)
- SQL Server (for data storage/querying)
- Tableau (for visualization)

## PR Guidelines

- Document any new data sources or methodology changes.
- Keep SQL queries formatted and commented.
- Don't commit large data files — use `.gitignore` or link to sources.
