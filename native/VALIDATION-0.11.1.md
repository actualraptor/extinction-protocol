# 0.11.1 validation

Boss resistance: 35 damage checks, 12 HUD checks; existing boss harvest 58, lifecycle integration 214, weapon/phase 54 checks passed. Resistance applies once to damage, crits and subsequent status ticks. Vulnerable windows, anchor shell and overkill accounting verified.

Luck: 4,208 checks passed, including every noncommon tier, Artifact, normalized odds, cap, rank quality/permanent Luck, and real level/chest RNG replay. Existing relic suite: 940 checks passed.

Tiered buff integration passed: actual weighted combat bonuses, armor/health, discrete echoes, new weapon ranks, legacy fallback, rerolls, reports and Daily options. Stone card layout: 1,154 checks across 1024, 1280 and 3440 widths; actual Artifact descriptions reviewed in screenshots.

Kael slam: 23 impact-timing checks and 78 asset checks passed. Normal/Halloween sequences rendered in eight gameplay screenshots. Damage occurs once at impact; windup and recovery fit 1.5, 0.4 and 0.12-second cadences. Movement stays independent; upgrade pause freezes windup; retired weapon cancels pending hits; bosses cannot be knocked back.

Full run regression: 3,417 checks passed. Six repeated run lifecycle checks passed with stable node counts.

Windows package smoke is recorded in build/package-0111.log and package-preview.png. Linux export is supplied as UNVERIFIED because it was not executed on Linux. Certificate-store and user shader-cache warnings in the restricted Windows environment do not indicate script failures.

Playtest needed: resistance numbers are a first tuning pass, not proof that every weak build loses or every strong build wins. Kael uses a front three-quarter sequence mirrored left; dedicated rear attack art is not included.

Voice rename: 18 originals and 18 runtime copies verified by SHA-256. Reimported all renamed MP3s; survivor voice suite passed 161 checks. Rebuilt both exports and reran graphical Windows package smoke after renaming. No script or missing-resource errors.
