import { describe, expect, it } from "vitest";
import {
  amountForPlayer,
  ceilDiv,
  computeCostSplit,
} from "../src/domain/cost";

describe("cost split rounding", () => {
  it("rounds each non-organizer share up", () => {
    const split = computeCostSplit(20000, 6);
    expect(split.perPlayer).toBe(3334);
    expect(split.organizerShare).toBe(3330);
    expect(split.organizerShare + split.perPlayer * 5).toBe(20000);
  });

  it("keeps the sum exactly equal to the booking total", () => {
    const totals = [12000, 15000, 20000, 22500, 25000, 33333];
    for (const total of totals) {
      for (let players = 1; players <= 40; players += 1) {
        const split = computeCostSplit(total, players);
        expect(split.organizerShare + split.perPlayer * (players - 1)).toBe(
          total,
        );
        expect(Number.isInteger(split.perPlayer)).toBe(true);
        expect(Number.isInteger(split.organizerShare)).toBe(true);
      }
    }
  });

  it("splits evenly when the total divides cleanly", () => {
    const split = computeCostSplit(22500, 10);
    expect(split.perPlayer).toBe(2250);
    expect(split.organizerShare).toBe(2250);
  });

  it("charges the organizer the full amount when alone", () => {
    const split = computeCostSplit(20000, 1);
    expect(split.organizerShare).toBe(20000);
  });

  it("assigns the rounding remainder to the organizer", () => {
    const split = computeCostSplit(25000, 14);
    expect(split.perPlayer).toBe(1786);
    expect(amountForPlayer(split, "organizer", "organizer")).toBe(1782);
    expect(amountForPlayer(split, "player", "organizer")).toBe(1786);
  });

  it("rejects invalid inputs", () => {
    expect(() => computeCostSplit(20000, 0)).toThrow();
    expect(() => computeCostSplit(-1, 2)).toThrow();
    expect(() => computeCostSplit(20000.5, 2)).toThrow();
    expect(() => ceilDiv(10, 0)).toThrow();
  });
});
