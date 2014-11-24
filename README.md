Melee Random Crits
==================

A plugin for SourceMod that can disable random crits on all weapons except for melee weapons.

Obsoleted in the 2014-10-30 update with the new ConVar "tf_weapon_criticals_melee" in combination with "tf_weapon_criticals".

Features
--------

* adds "no random crits" attribute to all non-melee weapons in order to allow weapons to function normally with crit boosts.

Usage
-----

**CVars**

* `random_melee_crits_version` - Melee Random Crits version
* `random_melee_crits_selection <0|1|2>` - sets which weapons should be allowed to randomly crit (0: no weapons, 1: melee weapons, 2: all weapons)
* `random_melee_crits_debug` - set whether the nocrit attribute is visible

Requirements
------------

* SourceMod
* TF2Attributes
* TF2Items
* TF2ItemsInfo

Changelog
---------

**1.4.0** (2014-01-13)
* made TF2Items a required dependency (fixes hooking errors)
* fixed variable shadowing warning

**1.3.2** (2014-01-12)
* fixed nocrits tag not being set for only melee crits

**1.3.1** (2014-01-12)
* moved tag set to timer

**1.3.0** (2014-01-12)
* added handling of tf_weapon_criticals
* added proper removal of attributes when switching states

**1.2.0** (2014-01-07)
* fixed race condition with TF2Items (bug in TF2Items?)
* added debug
* removed removal of attributes

**1.1.0** (2014-01-07)
* fixed plugin not using correct slot for melee
* added nocrits tag when enabled
* added enable/disable hook

**1.0.1** (2013-10-02)
* fixed documentation

**1.0.0** (2013-10-02)
* initial release

Installation
------------

1. Place `plugins/random-melee-crits.smx` in your `plugins` directory.
