const path = require("path");
const PptxGenJS = require("pptxgenjs");
const xlsx = require("xlsx");

const ROOT = path.resolve(__dirname, "..");
const DOCS = path.join(ROOT, "docs");
const OUTFILE = path.join(ROOT, "Final-Project-Presentation.pptx");
const COLORS = {
  titleBg: "4A0F19",
  header: "8F1D2C",
  headerText: "FFFFFF",
  subtitle: "7A2E3A",
  bodyText: "2E2225",
  panelSoft: "FCEFF1",
  panelSoftLine: "E8C8CF",
  panelWarm: "F9F0EB",
  panelWarmLine: "E9CFC8",
  statEstimated: "7C1D2A",
  statActual: "B33447",
  statVariance: "6A0F1C",
  chartA: "8F1D2C",
  chartB: "C2475A",
  chartC: "D97886",
  chartD: "5A0E18",
  titleAccent: "F8DBE1",
  titleAccent2: "EFC0CA",
  closingNote: "FCEEF2",
};

function toNumber(value) {
  const n = Number(String(value ?? "").replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
}

function loadPlannerMetrics() {
  const wb = xlsx.readFile(path.join(DOCS, "planner.xlsx"));
  const rows = xlsx.utils.sheet_to_json(wb.Sheets["query (8)"], {
    defval: "",
    raw: false,
  });

  const devTasks = rows.filter(
    (r) => String(r.TaskType).trim() === "Task" && toNumber(r.EstimatedHours) > 0
  );

  const estimated = devTasks.reduce((sum, r) => sum + toNumber(r.EstimatedHours), 0);
  const actual = devTasks.reduce((sum, r) => sum + toNumber(r.ActualHours), 0);
  const variance = actual - estimated;

  const completedCount = devTasks.filter(
    (r) => String(r.Complete).trim().toLowerCase() === "completed"
  ).length;

  const overruns = [...devTasks]
    .filter((r) => toNumber(r.HoursVariance) > 0)
    .sort((a, b) => toNumber(b.HoursVariance) - toNumber(a.HoursVariance))
    .slice(0, 3)
    .map((r) => ({
      title: String(r.Title).trim(),
      variance: toNumber(r.HoursVariance),
      actual: toNumber(r.ActualHours),
      estimated: toNumber(r.EstimatedHours),
    }));

  const underruns = [...devTasks]
    .filter((r) => toNumber(r.HoursVariance) < 0)
    .sort((a, b) => toNumber(a.HoursVariance) - toNumber(b.HoursVariance))
    .slice(0, 3)
    .map((r) => ({
      title: String(r.Title).trim(),
      variance: toNumber(r.HoursVariance),
      actual: toNumber(r.ActualHours),
      estimated: toNumber(r.EstimatedHours),
    }));

  return {
    estimated,
    actual,
    variance,
    completedCount,
    totalCount: devTasks.length,
    overruns,
    underruns,
  };
}

function loadTestMetrics() {
  const wb = xlsx.readFile(path.join(DOCS, "Test Executions.xlsx"));
  const rows = xlsx.utils.sheet_to_json(wb.Sheets["Test Executions"], {
    defval: "",
    raw: false,
  });

  const counts = { Passed: 0, Blocked: 0, Failed: 0 };
  for (const row of rows) {
    const status = String(row.ExecutionResult).trim();
    if (Object.prototype.hasOwnProperty.call(counts, status)) {
      counts[status] += 1;
    }
  }

  const nonPass = rows
    .filter((r) => {
      const s = String(r.ExecutionResult).trim();
      return s === "Blocked" || s === "Failed";
    })
    .map((r) => ({
      title: String(r.Title).trim(),
      result: String(r.ExecutionResult).trim(),
      notes: String(r.Notes).trim(),
    }));

  return {
    total: rows.length,
    passed: counts.Passed,
    blocked: counts.Blocked,
    failed: counts.Failed,
    nonPass,
  };
}

function bulletLines(items) {
  return items.map((line) => ({
    text: line,
    options: { bullet: { indent: 16 }, breakLine: true },
  }));
}

function addSectionTitle(slide, title, subtitle = "") {
  slide.addShape("rect", {
    x: 0,
    y: 0,
    w: 13.333,
    h: 0.78,
    fill: { color: COLORS.header },
    line: { color: COLORS.header },
  });

  slide.addText(title, {
    x: 0.5,
    y: 0.16,
    w: 8.8,
    h: 0.42,
    fontFace: "Calibri",
    fontSize: 24,
    bold: true,
    color: COLORS.headerText,
  });

  if (subtitle) {
    slide.addText(subtitle, {
      x: 0.5,
      y: 0.86,
      w: 12.2,
      h: 0.35,
      fontFace: "Calibri",
      fontSize: 14,
      italic: true,
      color: COLORS.subtitle,
    });
  }
}

function hoursText(value) {
  return `${value.toFixed(2)}h`;
}

function percentText(value, total) {
  if (!total) return "0.0%";
  return `${((value / total) * 100).toFixed(1)}%`;
}

function run() {
  const planner = loadPlannerMetrics();
  const tests = loadTestMetrics();
  const passedPct = percentText(tests.passed, tests.total);
  const blockedPct = percentText(tests.blocked, tests.total);
  const failedPct = percentText(tests.failed, tests.total);

  const pptx = new PptxGenJS();
  pptx.layout = "LAYOUT_WIDE";
  pptx.author = "Stephen Wilton";
  pptx.company = "CIS354";
  pptx.subject = "Project 7 Final Presentation";
  pptx.title = "Project 7 - Wave-Based Survival Game";
  pptx.lang = "en-US";
  pptx.theme = {
    headFontFace: "Calibri",
    bodyFontFace: "Calibri",
    lang: "en-US",
  };

  // Slide 1 - Title
  {
    const slide = pptx.addSlide();
    slide.background = { color: COLORS.titleBg };
    slide.addShape("roundRect", {
      x: 0.7,
      y: 0.8,
      w: 11.9,
      h: 5.9,
      rectRadius: 0.08,
      fill: { color: COLORS.header, transparency: 8 },
      line: { color: COLORS.titleAccent2, pt: 1.2, transparency: 15 },
    });

    slide.addText("Project 7", {
      x: 1.2,
      y: 1.9,
      w: 10.8,
      h: 0.8,
      align: "center",
      fontFace: "Calibri",
      fontSize: 46,
      bold: true,
      color: "FFFFFF",
    });
    slide.addText("Final Project Presentation", {
      x: 1.2,
      y: 2.75,
      w: 10.8,
      h: 0.55,
      align: "center",
      fontFace: "Calibri",
      fontSize: 26,
      color: COLORS.titleAccent,
    });
    slide.addText("Wave-Based Survival Game (Godot 4)", {
      x: 1.2,
      y: 3.38,
      w: 10.8,
      h: 0.5,
      align: "center",
      fontFace: "Calibri",
      fontSize: 18,
      color: COLORS.titleAccent2,
    });
    slide.addText("Student: Stephen Wilton | Date: April 15, 2026", {
      x: 1.2,
      y: 4.45,
      w: 10.8,
      h: 0.4,
      align: "center",
      fontFace: "Calibri",
      fontSize: 14,
      color: COLORS.closingNote,
    });
  }

  // Slide 2 - Application Overview
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Application Overview");
    slide.addText(
      bulletLines([
        "I set out to build a Vampire Survivors/Brotato-style survival game with action-oriented gameplay, scaling difficulty, and meaningful progression.",
        "Intended users are players who enjoy arcade-style survival gameplay and roguelite elements.",
        "For CIS354, the project also had to demonstrate SDLC execution, planning discipline, testing evidence, and honest reflection.",
        "Development was done on Windows using Godot 4 and GDScript, delivered as `Game/Project7.exe`.",
        "Delivered systems include movement/dash, melee+ranged combat, enemy variants, wave progression, passives/level-ups, shop economy, menus, save/load, and final-wave victory flow.",
      ]),
      {
        x: 0.75,
        y: 1.35,
        w: 12.0,
        h: 5.75,
        fontFace: "Calibri",
        fontSize: 18,
        color: COLORS.bodyText,
        valign: "top",
      }
    );
  }

  // Slide 3 - Live Demonstration Plan
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Live Demonstration", "Realistic player scenario walkthrough");

    slide.addShape("roundRect", {
      x: 0.7,
      y: 1.35,
      w: 6.2,
      h: 5.8,
      rectRadius: 0.05,
      fill: { color: COLORS.panelSoft },
      line: { color: COLORS.panelSoftLine, pt: 1 },
    });
    slide.addText("Demo Flow", {
      x: 0.95,
      y: 1.55,
      w: 5.6,
      h: 0.35,
      fontFace: "Calibri",
      fontSize: 18,
      bold: true,
      color: COLORS.header,
    });
    slide.addText(
      bulletLines([
        "Launch from main menu and start a run.",
        "Show wave combat: movement, dash, melee/ranged attacks, enemy pressure.",
        "Demonstrate currency pickup and between-wave shop decisions (lock/refresh/combine).",
        "Show progression behavior (end-of-wave level-up and passive choices).",
        "Reach late-wave pressure and finish with victory/game-over flow.",
      ]),
      {
        x: 0.95,
        y: 2.0,
        w: 5.6,
        h: 4.95,
        fontFace: "Calibri",
        fontSize: 15,
        color: COLORS.bodyText,
      }
    );

    slide.addShape("roundRect", {
      x: 6.95,
      y: 1.35,
      w: 5.65,
      h: 5.8,
      rectRadius: 0.05,
      fill: { color: COLORS.panelWarm },
      line: { color: COLORS.panelWarmLine, pt: 1 },
    });
    slide.addText("What To Highlight During Demo", {
      x: 7.2,
      y: 1.55,
      w: 5.2,
      h: 0.35,
      fontFace: "Calibri",
      fontSize: 18,
      bold: true,
      color: COLORS.statVariance,
    });
    slide.addText(
      bulletLines([
        "Data interaction: save/load uses local JSON state.",
        "Systems integration: HUD, audio cues, wave pacing, and pause behavior.",
        "Testing-informed fixes: pause-state combat bugs, spawn and projectile edge cases.",
        "Be transparent about simplified areas (e.g., game-over stats not implemented).",
      ]),
      {
        x: 7.2,
        y: 2.0,
        w: 5.2,
        h: 4.95,
        fontFace: "Calibri",
        fontSize: 15,
        color: COLORS.bodyText,
      }
    );
  }

  // Slide 4 - Challenges
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Challenges And How They Were Addressed");
    slide.addText(
      bulletLines([
        "Shop system was the biggest challenge (13.00h actual vs 4.00h estimated, +9.00h). Rerolls, locks, combines, and between-wave transitions created more edge cases than originally scoped.",
        "Passives/Levelup required more iteration than expected (9.00h vs 4.00h, +5.00h). Early assumptions about progression feel did not fully hold up during playtesting.",
        "Tooltip/UI detail work took extra polish time (1.50h vs 1.00h, +0.50h) because readability and context-sensitive behavior needed multiple passes.",
        "External testing feedback timing was slower in the late phase, so I shifted effort toward internal validation, documentation, and release readiness.",
      ]),
      {
        x: 0.75,
        y: 1.35,
        w: 12.0,
        h: 5.75,
        fontFace: "Calibri",
        fontSize: 17,
        color: COLORS.bodyText,
      }
    );
  }

  // Slide 5 - Budget Review
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Budget Review (Actual vs Estimated)");

    slide.addShape("roundRect", {
      x: 0.75,
      y: 1.25,
      w: 4.0,
      h: 1.25,
      rectRadius: 0.04,
      fill: { color: COLORS.panelSoft },
      line: { color: COLORS.panelSoftLine, pt: 1 },
    });
    slide.addText("Estimated", {
      x: 0.95,
      y: 1.48,
      w: 1.8,
      h: 0.25,
      fontSize: 13,
      bold: true,
      color: COLORS.statEstimated,
    });
    slide.addText(hoursText(planner.estimated), {
      x: 0.95,
      y: 1.72,
      w: 3.5,
      h: 0.5,
      fontSize: 28,
      bold: true,
      color: COLORS.statEstimated,
    });

    slide.addShape("roundRect", {
      x: 4.95,
      y: 1.25,
      w: 4.0,
      h: 1.25,
      rectRadius: 0.04,
      fill: { color: "FBEFF2" },
      line: { color: "E6C3CB", pt: 1 },
    });
    slide.addText("Actual", {
      x: 5.15,
      y: 1.48,
      w: 1.8,
      h: 0.25,
      fontSize: 13,
      bold: true,
      color: COLORS.statActual,
    });
    slide.addText(hoursText(planner.actual), {
      x: 5.15,
      y: 1.72,
      w: 3.5,
      h: 0.5,
      fontSize: 28,
      bold: true,
      color: COLORS.statActual,
    });

    slide.addShape("roundRect", {
      x: 9.15,
      y: 1.25,
      w: 3.45,
      h: 1.25,
      rectRadius: 0.04,
      fill: { color: COLORS.panelWarm },
      line: { color: COLORS.panelWarmLine, pt: 1 },
    });
    slide.addText("Variance", {
      x: 9.35,
      y: 1.48,
      w: 1.5,
      h: 0.25,
      fontSize: 13,
      bold: true,
      color: COLORS.statVariance,
    });
    slide.addText(
      `${planner.variance > 0 ? "+" : ""}${hoursText(planner.variance)} (${planner.variance <= 0 ? "under" : "over"})`,
      {
        x: 9.35,
        y: 1.72,
        w: 3.0,
        h: 0.5,
        fontSize: 22,
        bold: true,
        color: COLORS.statVariance,
      }
    );

    slide.addChart(
      pptx.ChartType.bar,
      [
        { name: "Estimated", labels: ["Hours"], values: [planner.estimated] },
        { name: "Actual", labels: ["Hours"], values: [planner.actual] },
      ],
      {
        x: 0.95,
        y: 2.8,
        w: 4.8,
        h: 3.8,
        barDir: "col",
        catAxisHidden: false,
        valAxisHidden: false,
        showLegend: true,
        legendPos: "b",
        valAxisMinVal: 0,
        valAxisMaxVal: Math.ceil(planner.estimated + 10),
        chartColors: [COLORS.chartA, COLORS.chartB],
      }
    );

    const overrunLines = planner.overruns.map(
      (t) => `${t.title}: +${hoursText(t.variance)} (${hoursText(t.actual)}/${hoursText(t.estimated)})`
    );
    const underrunLines = planner.underruns.map(
      (t) =>
        `${t.title}: ${hoursText(t.variance)} (${hoursText(t.actual)}/${hoursText(t.estimated)})`
    );

    slide.addText("Largest Overruns", {
      x: 6.1,
      y: 2.95,
      w: 3.2,
      h: 0.32,
      fontSize: 15,
      bold: true,
      color: COLORS.statVariance,
    });
    slide.addText(bulletLines(overrunLines), {
      x: 6.1,
      y: 3.25,
      w: 6.2,
      h: 1.6,
      fontSize: 13,
      color: COLORS.bodyText,
    });

    slide.addText("Largest Underruns", {
      x: 6.1,
      y: 4.95,
      w: 3.2,
      h: 0.32,
      fontSize: 15,
      bold: true,
      color: COLORS.header,
    });
    slide.addText(bulletLines(underrunLines), {
      x: 6.1,
      y: 5.25,
      w: 6.2,
      h: 1.5,
      fontSize: 13,
      color: COLORS.bodyText,
    });
  }

  // Slide 6 - Results
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Results");

    slide.addShape("roundRect", {
      x: 0.75,
      y: 1.35,
      w: 6.1,
      h: 5.75,
      rectRadius: 0.05,
      fill: { color: COLORS.panelSoft },
      line: { color: COLORS.panelSoftLine, pt: 1 },
    });
    slide.addText("What Was Completed", {
      x: 1.0,
      y: 1.55,
      w: 5.6,
      h: 0.35,
      fontSize: 18,
      bold: true,
      color: COLORS.header,
    });
    slide.addText(
      bulletLines([
        `Development tasks completed: ${planner.completedCount}/${planner.totalCount}.`,
        "By Week 10, core gameplay and major systems were complete, so the final phase shifted to testing and documentation.",
        "Final deliverables include a playable Windows build plus testing, retrospective, and budget artifacts.",
        `Testing outcomes: ${tests.total} executions (${tests.passed} passed, ${tests.blocked} blocked, ${tests.failed} failed).`,
      ]),
      {
        x: 1.0,
        y: 2.0,
        w: 5.55,
        h: 4.85,
        fontSize: 15,
        color: COLORS.bodyText,
      }
    );

    slide.addChart(
      pptx.ChartType.doughnut,
      [
        {
          name: "Testing",
          labels: ["Passed", "Blocked", "Failed"],
          values: [tests.passed, tests.blocked, tests.failed],
        },
      ],
      {
        x: 6.95,
        y: 1.55,
        w: 5.15,
        h: 2.85,
        showLegend: true,
        legendPos: "r",
        holeSize: 56,
        showValue: true,
        showPercent: true,
        dataLabelPosition: "bestFit",
        dataLabelFormatCode: "0.0%",
        chartColors: [COLORS.chartA, COLORS.chartC, COLORS.chartD],
      }
    );

    slide.addText(
      bulletLines([
        `Passed: ${tests.passed} (${passedPct})`,
        `Blocked: ${tests.blocked} (${blockedPct})`,
        `Failed: ${tests.failed} (${failedPct})`,
      ]),
      {
        x: 6.95,
        y: 4.15,
        w: 5.1,
        h: 0.95,
        fontSize: 13,
        color: COLORS.bodyText,
      }
    );

    const residuals = tests.nonPass.map((item) => `${item.title} (${item.result}): ${item.notes}`);
    slide.addText("What Remained Incomplete Or Simplified", {
      x: 7.15,
      y: 4.55,
      w: 4.95,
      h: 0.32,
      fontSize: 15,
      bold: true,
      color: COLORS.statVariance,
    });
    slide.addText(bulletLines(residuals), {
      x: 7.15,
      y: 4.9,
      w: 5.0,
      h: 2.05,
      fontSize: 13,
      color: COLORS.bodyText,
    });
  }

  // Slide 7 - Success Factors
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Success Factors");
    slide.addText(
      bulletLines([
        "The project went well because the structure stayed flexible enough to keep adding, testing, and changing features as development progressed.",
        "A modular scene/component approach in Godot reduced implementation friction and made systems reusable.",
        "Active scope management protected delivery: when features risked overruns, I simplified or deferred instead of expanding indefinitely.",
        "Planner checkpoints, weekly notes, patch notes, and test workbooks kept progress and tradeoffs visible.",
        "Completing core systems early created enough runway for testing, documentation, and final presentation readiness.",
      ]),
      {
        x: 0.75,
        y: 1.35,
        w: 12.0,
        h: 5.75,
        fontFace: "Calibri",
        fontSize: 18,
        color: COLORS.bodyText,
      }
    );
  }

  // Slide 8 - Reflection and Improvements
  {
    const slide = pptx.addSlide();
    addSectionTitle(slide, "Reflection And Improvements");

    slide.addShape("roundRect", {
      x: 0.75,
      y: 1.35,
      w: 5.95,
      h: 5.8,
      rectRadius: 0.05,
      fill: { color: COLORS.panelSoft },
      line: { color: COLORS.panelSoftLine, pt: 1 },
    });
    slide.addText("What I Would Change Next Time", {
      x: 1.0,
      y: 1.55,
      w: 5.5,
      h: 0.35,
      fontSize: 17,
      bold: true,
      color: COLORS.header,
    });
    slide.addText(
      bulletLines([
        "I would define architecture boundaries for progression, shop, and menu state earlier to reduce late-stage coupling.",
        "I would estimate by risk class, not just feature labels, because UI/state-heavy systems need larger uncertainty buffers.",
        "I would schedule integration checkpoints earlier so hidden interaction issues appear before final-week pressure.",
        "I would start structured execution and lightweight regression checklists earlier in the cycle.",
      ]),
      {
        x: 1.0,
        y: 2.0,
        w: 5.45,
        h: 4.9,
        fontSize: 14,
        color: COLORS.bodyText,
      }
    );

    slide.addShape("roundRect", {
      x: 7.0,
      y: 1.35,
      w: 5.6,
      h: 5.8,
      rectRadius: 0.05,
      fill: { color: COLORS.panelWarm },
      line: { color: COLORS.panelWarmLine, pt: 1 },
    });
    slide.addText("Professional Takeaway", {
      x: 7.25,
      y: 1.55,
      w: 5.1,
      h: 0.35,
      fontSize: 17,
      bold: true,
      color: COLORS.statVariance,
    });
    slide.addText(
      "I am satisfied with the final product and process outcome. The most valuable lesson was that estimation accuracy depends more on interaction complexity than on feature count.",
      {
        x: 7.25,
        y: 2.0,
        w: 5.05,
        h: 1.6,
        fontSize: 15,
        color: COLORS.bodyText,
        valign: "top",
      }
    );
    slide.addText("Next Project Focus Areas", {
      x: 7.25,
      y: 3.9,
      w: 5.1,
      h: 0.3,
      fontSize: 15,
      bold: true,
      color: COLORS.statVariance,
    });
    slide.addText(
      bulletLines([
        "Earlier architecture guardrails for state-heavy systems.",
        "More formal external tester handoff timing.",
        "Automated or checklist-driven regression support.",
      ]),
      {
        x: 7.25,
        y: 4.2,
        w: 5.0,
        h: 2.5,
        fontSize: 14,
        color: COLORS.bodyText,
      }
    );
  }

  // Slide 9 - Closing
  {
    const slide = pptx.addSlide();
    slide.background = { color: COLORS.header };
    slide.addText("Project 7 - Final Presentation", {
      x: 0.9,
      y: 2.0,
      w: 11.5,
      h: 0.8,
      align: "center",
      fontFace: "Calibri",
      fontSize: 34,
      bold: true,
      color: "FFFFFF",
    });
    slide.addText("Questions?", {
      x: 0.9,
      y: 3.0,
      w: 11.5,
      h: 0.8,
      align: "center",
      fontFace: "Calibri",
      fontSize: 38,
      bold: true,
      color: COLORS.titleAccent,
    });
    slide.addText(
      "Evidence sources: planner, budget checkpoints, retrospective, weekly notes, patch notes, test plan, test cases, and test executions.",
      {
        x: 1.1,
        y: 5.15,
        w: 11.1,
        h: 0.8,
        align: "center",
        fontFace: "Calibri",
        fontSize: 13,
        color: COLORS.closingNote,
      }
    );
  }

  pptx.writeFile({ fileName: OUTFILE });
  console.log(`Presentation generated: ${OUTFILE}`);
}

run();
