# Development Retrospective Report
**Project:** Project 7 - Wave-Based Survival Game  
**Student:** Stephen Wilton  
**Date:** April 8, 2026

## 1. Project Overview
The project goal was to build a Vampire Survivors/Brotato-style survival game with short action loops, escalating difficulty, and meaningful between-wave progression. The intended users were players who enjoy arcade-style survival gameplay, and academically, the instructor and course evaluators who assessed design, execution, and documentation quality.

Development was done on Windows using Godot 4 and GDScript, with planning tracked in the project planner and supporting documentation in weekly progress notes, patch notes, and testing workbooks. The final build target was Windows PC (`Game/Project7.exe`).

Key features delivered include player movement and dash, melee and ranged combat, enemy spawning and variants, progression through passives/level-ups, currency and shop systems (including lock/refresh/combine behavior), menus (title/options/pause/game over), save/load, HUD/audio systems, and an endgame flow (final wave and victory screen).

## 2. Development Process Reflection
Planned versus actual development was generally favorable but uneven by feature type. Across the 27 development task rows with estimates, planned effort was 84.50 hours and actual effort finished at 71.00 hours, for a net variance of -13.50 hours. This means the project completed under estimate overall, but some systems still had significant overruns.

Milestones evolved from feature-building to integration and documentation earlier than expected. By Week 10, core gameplay and major systems were feature-complete, and Weeks 12-13 shifted to testing coordination, documentation, and final deliverables instead of new implementation. This was a positive shift, but it also showed that milestone tracking can lag behind reality when planner updates are not immediate.

Task completion accuracy ended strong: all 27 estimated development tasks are marked completed. However, estimate quality varied: straightforward systems were often overestimated, while state-heavy UI/progression systems (especially shop and passives) were underestimated.

## 3. What Went Well
One of the best technical decisions was using a modular, scene/component-oriented approach in Godot. Reusable patterns for health/combat/UI behavior reduced implementation friction later in the project and helped keep many foundational tasks under estimate.

Godot as a framework worked well for iteration speed. Scene instancing, resource-driven configuration, and built-in systems made it faster to build and tune gameplay loops than expected. Planning and tracking tools (planner, checkpoints, weekly notes, and test sheets) also helped maintain visibility on progress and tradeoffs.

Project management was strongest when scope decisions were made early and explicitly. Features that risked derailing schedule were simplified or deferred instead of expanding indefinitely. Collaboration was limited but still useful: external testing support was arranged, and peer testing responsibilities were handled even while final documents were being completed.

## 4. Challenges
**Challenge 1: Shop system complexity**  
What happened: Shop System finished at 13.00 actual hours versus 4.00 estimated (+9.00).  
Why it happened: UI state, rerolls, locks, combines, and between-wave transitions created more edge cases than initially scoped.  
Impact: This became the single largest time overrun and consumed buffer that could have gone to extra polish.

**Challenge 2: Progression behavior and level-up expectations**  
What happened: Progression goals changed during development, including how level-up timing should feel in real gameplay. One execution was blocked due to desired behavior not matching current implementation at that stage.  
Why it happened: Initial assumptions about progression flow were not fully validated early with playtesting.  
Impact: Additional rework/tuning time was required, and some behavior was simplified to keep delivery stable.

**Challenge 3: Tooltip and UI detail work**  
What happened: Tooltip behavior and UI clarity took longer than expected and required multiple polish passes.  
Why it happened: Small UX features had hidden complexity in readability, consistency, and context-sensitive display.  
Impact: Minor schedule pressure and shifted attention away from lower-priority enhancements.

**Challenge 4: Testing communication dependency**  
What happened: External feedback loops were slower than expected during late-stage testing coordination.  
Why it happened: Testing depended on communication timing and availability from others.  
Impact: Late-phase work focused more on documentation/handoff readiness and less on externally-driven bug feedback.

## 5. Testing Phase Insights
The testing artifacts were useful and actionable. The test case workbook covered broad gameplay and system behavior, and the execution workbook captured concrete observations that guided fixes. Test coverage was mostly functional, with additional UI, integration, and limited performance checks.

From the test logs, there were 35 recorded executions: 32 passed, 2 blocked, and 1 failed. Issues discovered included collision signal wiring, ranged direction targeting, accuracy stacking behavior, hitbox persistence behavior, tooltip implementation complexity, and some scope-specific gaps (for example, game-over stat reporting and environmental hazard depth).

The biggest testing gap was depth and diversity of testing strategy. Testing was primarily manual and heavily single-tester driven, with no automated regression suite and limited stress/performance profiling at scale. Even so, testing clearly improved final quality by exposing gameplay bugs early enough to fix, and by forcing explicit scope decisions where full implementation was not worth schedule risk.

## 6. Time and Budget Reflection
Estimate accuracy was mixed but manageable. Final development effort was under budget overall (-13.50 hours), but this headline hides concentration risk in a few systems. High time consumption areas were Shop System (13.00h), Passives/Levelup (9.00h), Melee Attacks (6.00h), and Player Movement (5.00h).

Over-estimation happened mostly in foundational or reusable systems; under-estimation happened in integration-heavy gameplay loops and UI state management. The two largest overruns were Shop (+9.00) and Passives/Levelup (+5.00). The largest under-runs were Enemy Variants (-5.00), Player Movement (-3.00), and Performance (-3.00 logged with no dedicated sprint).

Budget alignment remained healthy because strong under-runs in many tasks offset concentrated overruns in a few complex systems. What made things run smoothly was not luck: the architecture was reusable, scope was actively managed, and difficult features were time-boxed instead of allowed to expand indefinitely.

## 7. Technical Growth
Technically, I improved most in system integration and state management. Building isolated features is one skill; making menus, combat, progression, and wave flow behave correctly together is another. I became more comfortable with debugging cross-system interactions and edge-case timing bugs.

I also improved in coding practice around modularity and reuse. Defining systems in cleaner components/resources made later features faster to add and tune. On debugging, I gained confidence in tracing root causes from user-facing symptoms, especially for signal/connection issues and gameplay logic regressions.

Most importantly, I strengthened my understanding of practical system design: decisions that look small (such as progression timing or shop state handling) can dominate schedule and quality if they are tightly coupled and not validated early.

## 8. What I Would Do Differently
If I repeated this project, I would define architecture boundaries for progression/shop/menu state earlier, with stricter interfaces and fewer cross-dependencies. That would reduce rework in late-stage tuning.

For planning, I would estimate by risk class, not just by feature label. UI/state-heavy systems need larger uncertainty buffers than straightforward mechanics. I would also schedule earlier integration checkpoints so that hidden coupling issues are found before final-week crunch.

For testing, I would start structured execution earlier and add lightweight regression checklists after each major feature merge. I would also formalize external tester handoff timing sooner to reduce communication bottlenecks during the final phase.

## 9. Final Reflection
I am satisfied with the final product and the process outcome. The core objectives were achieved: a playable, complete survival game with progression, combat variety, UI flows, and supporting documentation/testing artifacts. The most valuable lesson was that estimation accuracy depends more on interaction complexity than on feature count.

Overall, this project improved both my technical execution and my project judgment. I finished with a better understanding of SDLC tradeoffs, stronger debugging discipline, and a more realistic approach to planning and scope control.
