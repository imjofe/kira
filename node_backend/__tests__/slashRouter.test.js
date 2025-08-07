import { parseSlashCommand, slashRouter } from "../src/middleware/slashRouter.js";

describe("slashRouter.parseSlashCommand", () => {
  it("accepts whitelisted commands", () => {
    expect(parseSlashCommand("/mode=json")).toBe("/mode=json");
    expect(parseSlashCommand("/debug")).toBe("/debug");
    expect(parseSlashCommand("/summarize")).toBe("/summarize");
    expect(parseSlashCommand("/sql")).toBe("/sql");
    expect(parseSlashCommand("/rephrase")).toBe("/rephrase");
  });

  it("rejects unknown commands", () => {
    expect(parseSlashCommand("/hax")).toBeNull();
    expect(parseSlashCommand(" /mode=json ")).toBeNull(); // spacing matters
    expect(parseSlashCommand("/unknown")).toBeNull();
    expect(parseSlashCommand("/mode=xml")).toBeNull();
  });

  it("rejects non-slash commands", () => {
    expect(parseSlashCommand("mode=json")).toBeNull();
    expect(parseSlashCommand("regular text")).toBeNull();
    expect(parseSlashCommand("")).toBeNull();
  });

  it("is case sensitive", () => {
    expect(parseSlashCommand("/DEBUG")).toBeNull();
    expect(parseSlashCommand("/Mode=json")).toBeNull();
    expect(parseSlashCommand("/SUMMARIZE")).toBeNull();
  });
});

describe("slashRouter middleware", () => {
  it("sets req.slashCommand for valid commands", () => {
    const req = { body: { content: "/debug" } };
    const res = {};
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    slashRouter(req, res, next);

    expect(req.slashCommand).toBe("/debug");
    expect(nextCalled).toBe(true);
  });

  it("sets req.slashCommand to null for invalid commands", () => {
    const req = { body: { content: "/invalid" } };
    const res = {};
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    slashRouter(req, res, next);

    expect(req.slashCommand).toBeNull();
    expect(nextCalled).toBe(true);
  });

  it("handles trimmed content", () => {
    const req = { body: { content: "  /mode=json  " } };
    const res = {};
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    slashRouter(req, res, next);

    expect(req.slashCommand).toBe("/mode=json");
    expect(nextCalled).toBe(true);
  });

  it("handles missing body gracefully", () => {
    const req = {};
    const res = {};
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    slashRouter(req, res, next);

    expect(req.slashCommand).toBeNull();
    expect(nextCalled).toBe(true);
  });

  it("handles missing content gracefully", () => {
    const req = { body: {} };
    const res = {};
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    slashRouter(req, res, next);

    expect(req.slashCommand).toBeNull();
    expect(nextCalled).toBe(true);
  });
});