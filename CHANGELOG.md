# Change Log

## [Unreleased](https://github.com/decidim/decidim/tree/HEAD)

### Added

### Changed

#### Generate Tailwind configuration on runtime

Decidim redesign has introduced Tailwind CSS framework to compile CSS. Decidim Webpacker integration
generates Tailwind configuration dynamically when Webpacker is invoked.

The technical reasons are in the content of the configuration file, it requires to specify a path to
all templates where CSS classes are used. Because of the Decidim gem configuration system, the list
of decidim gems installed can only be read on execution time.

Therefore, in case that your application has a `tailwind.config.js` file at the root folder, it
should be removed and ignored in git, because Decidim will overwrite it when assets are compiled.

### Fixed

### Removed

## Previous versions

Please check [release/0.27-stable](https://github.com/decidim/decidim/blob/release/0.27-stable/CHANGELOG.md) for previous changes.
