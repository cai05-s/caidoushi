# Backend Development Guidelines

> Best practices for backend development in this project.

---

## Overview

This directory contains guidelines for backend development. Fill in each file with your project's specific conventions.

---

## Guidelines Index

| Guide | Description | Status |
|-------|-------------|--------|
| [HX4S20 board memory](./hx4s20-board.md) | Canonical board resources, all pin tables, control roles and manual errata; read first for hardware work | Verified against manual and active constraints |
| [Day/night audio](./daynight-audio.md) | SW3 day/night, compact OSD, image melodies, brightness arithmetic, PCM and emergency priority | R6 built; board test pending |
| [FPGA frame cache](./fpga-frame-cache.md) | Active RTL, five-bank contracts, TD and board verification | Full bridge implemented; TD/board evidence in active task |
| [Flash record store](./flash-record-store.md) | Byte order, commit-last verification, bounded counters and resource checks | Resource increment; physical save/load acceptance pending |
| [Directory Structure](./directory-structure.md) | Module organization and file layout | To fill |
| [Database Guidelines](./database-guidelines.md) | ORM patterns, queries, migrations | To fill |
| [Error Handling](./error-handling.md) | Error types, handling strategies | To fill |
| [Quality Guidelines](./quality-guidelines.md) | Code standards, forbidden patterns | To fill |
| [Logging Guidelines](./logging-guidelines.md) | Structured logging, log levels | To fill |

---

## How to Fill These Guidelines

### Pre-development checklist for this FPGA project

Read [HX4S20 board memory](./hx4s20-board.md) before board-resource questions,
pin assignments or peripheral changes. Then read the FPGA frame-cache spec when
the task involves video/storage RTL. Generic web-backend template sections below
do not define the board's hardware contracts.

For each guideline file:

1. Document your project's **actual conventions** (not ideals)
2. Include **code examples** from your codebase
3. List **forbidden patterns** and why
4. Add **common mistakes** your team has made

The goal is to help AI assistants and new team members understand how YOUR project works.

---

**Language**: All documentation should be written in **English**.
