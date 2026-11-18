import { describe, expect, it } from "vitest";
import {
  allSlotIdsForDate,
  assertBookableRange,
  computeBookingPrice,
  dateKey,
  kigaliDateString,
  kigaliToUtc,
  slotIdsFor,
} from "../src/domain/slots";

function overlaps(a: string[], b: string[]): string[] {
  const set = new Set(a);
  return b.filter((id) => set.has(id));
}

describe("slot overlap protection", () => {
  it("produces one 30-minute doc per block", () => {
    expect(slotIdsFor("2026-11-14", "18:00", 90)).toEqual([
      "20261114_1800",
      "20261114_1830",
      "20261114_1900",
    ]);
  });

  it("detects overlapping bookings", () => {
    const first = slotIdsFor("2026-11-14", "18:00", 90);
    const second = slotIdsFor("2026-11-14", "18:30", 60);
    expect(overlaps(first, second)).toEqual([
      "20261114_1830",
      "20261114_1900",
    ]);
  });

  it("allows adjacent bookings that share no slot", () => {
    const first = slotIdsFor("2026-11-14", "18:00", 60);
    const second = slotIdsFor("2026-11-14", "19:00", 60);
    expect(overlaps(first, second)).toEqual([]);
  });

  it("covers every block from 07:00 to 22:00", () => {
    const ids = allSlotIdsForDate("2026-11-14");
    expect(ids).toHaveLength(30);
    expect(ids[0]).toBe("20261114_0700");
    expect(ids.at(-1)).toBe("20261114_2130");
  });

  it("rejects ranges outside opening hours", () => {
    expect(() =>
      assertBookableRange("2026-11-14", "06:30", 60, new Date("2026-01-01")),
    ).toThrow(/07:00 and 22:00/);
    expect(() =>
      assertBookableRange("2026-11-14", "21:30", 60, new Date("2026-01-01")),
    ).toThrow(/07:00 and 22:00/);
  });

  it("rejects times that are not 30-minute aligned", () => {
    expect(() =>
      assertBookableRange("2026-11-14", "18:15", 60, new Date("2026-01-01")),
    ).toThrow(/30-minute/);
  });

  it("rejects past kickoffs", () => {
    expect(() =>
      assertBookableRange("2026-11-14", "18:00", 60, new Date("2026-11-15")),
    ).toThrow(/past/);
  });

  it("accepts the last bookable hour", () => {
    expect(() =>
      assertBookableRange("2026-11-14", "21:00", 60, new Date("2026-01-01")),
    ).not.toThrow();
  });

  it("keeps slot IDs in Kigali local time", () => {
    expect(dateKey("2026-02-01")).toBe("20260201");
    const utc = kigaliToUtc("2026-02-01", "07:00");
    expect(utc.toISOString()).toBe("2026-02-01T05:00:00.000Z");
    expect(kigaliDateString(utc)).toBe("2026-02-01");
  });
});

describe("booking price", () => {
  it("computes integer RWF for 60, 90 and 120 minutes", () => {
    expect(computeBookingPrice(20000, 60)).toBe(20000);
    expect(computeBookingPrice(20000, 90)).toBe(30000);
    expect(computeBookingPrice(20000, 120)).toBe(40000);
    expect(computeBookingPrice(15000, 90)).toBe(22500);
  });

  it("never returns a fractional amount", () => {
    for (const price of [12000, 15000, 18000, 20000, 25000]) {
      for (const duration of [60, 90, 120] as const) {
        expect(Number.isInteger(computeBookingPrice(price, duration))).toBe(true);
      }
    }
  });
});
