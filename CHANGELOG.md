# ConfigurationsJutulDarcy.jl changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `FieldFileOptions` reads a field from a JLD2 file. Implemented in JLD2 extension. Field can be automatically resized to match grid size using ImageTransformations extension.
- Simple anisotropic permeability parameter `permeability_v_over_h` sets the ratio between the vertical permeability and the horizontal permeability.
- `:co2brine_simple` system is a simplified version of the `co2brine` system in JutulDarcy.

## [v0.0.4] - 2024-10-30

### Changed

- Made the structs hash-stable by removing all mutable types

## [v0.0.3] - 2024-10-30

### Added

- Added option to read field from file.

### Changed

- Specified type for each struct field.
- `FieldOptions` interface has been changed.

### Removed

- `FieldOptions` no longer has the ability to pad the boundary. Use JutulDarcy to
  set the boundary conditions instead.

## [v0.0.2] - 2024-10-17

### Added

- Support for well trajectory.
- `CO2BrineOptions` for parameters concerning the overall physics equations.

### Changed

- Updated JutulDarcy compatibility to v0.2.35.
- Updated Julia compatibility to v1.10.
- `WellOptions` has been simplified to better fit with JutulDarcy.

### Removed

- Jupyter notebooks built for documentation no longer show the executed results. The results are shown
  only in the markdown.


## [v0.0.1] - 2024-10-17

### Added

First labeled version. Compatible with JutulDarcy v0.2.26 and Julia 1.9 and higher.
