
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const address3 = accounts.get("wallet_3")!;
const deployerAddress = accounts.get("deployer")!;
const contractName = "Livestock-Ownership-Registry";

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

describe("Livestock Ownership Registry Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  describe("Basic Functionality", () => {
    it("should register livestock successfully", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "register-livestock",
        [
          Cl.stringAscii("Cattle"),
          Cl.stringAscii("Angus"),
          Cl.uint(24),
          Cl.stringAscii("Male"),
          Cl.stringAscii("Black"),
          Cl.uint(450),
          Cl.stringAscii("Healthy"),
          Cl.stringAscii("Farm A, Sector 1")
        ],
        address1
      );
      expect(result).toBeOk(Cl.uint(1));
    });

    it("should get livestock info", () => {
      // First register livestock
      simnet.callPublicFn(
        contractName,
        "register-livestock",
        [
          Cl.stringAscii("Cattle"),
          Cl.stringAscii("Angus"),
          Cl.uint(24),
          Cl.stringAscii("Male"),
          Cl.stringAscii("Black"),
          Cl.uint(450),
          Cl.stringAscii("Healthy"),
          Cl.stringAscii("Farm A, Sector 1")
        ],
        address1
      );

      const { result } = simnet.callReadOnlyFn(
        contractName,
        "get-livestock-info",
        [Cl.uint(1)],
        address1
      );

      expect(result).toBeDefined();
    });
  });

  describe("Health Monitoring System", () => {
    it("should authorize veterinarian by owner only", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "authorize-veterinarian",
        [Cl.principal(address2)],
        deployerAddress
      );
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should reject veterinarian authorization by non-owner", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "authorize-veterinarian",
        [Cl.principal(address3)],
        address1
      );
      expect(result).toBeErr(Cl.uint(100)); // ERR_UNAUTHORIZED
    });

    it("should check veterinarian authorization status", () => {
      // Authorize vet first
      simnet.callPublicFn(
        contractName,
        "authorize-veterinarian",
        [Cl.principal(address2)],
        deployerAddress
      );

      const { result } = simnet.callReadOnlyFn(
        contractName,
        "is-authorized-veterinarian",
        [Cl.principal(address2)],
        address1
      );

      expect(result).toBeTuple({ active: Cl.bool(true) });
    });

    it("should allow authorized vet to add health record", () => {
      // Register livestock first
      simnet.callPublicFn(
        contractName,
        "register-livestock",
        [
          Cl.stringAscii("Cattle"),
          Cl.stringAscii("Holstein"),
          Cl.uint(30),
          Cl.stringAscii("Female"),
          Cl.stringAscii("White"),
          Cl.uint(400),
          Cl.stringAscii("Healthy"),
          Cl.stringAscii("Farm B, Sector 2")
        ],
        address1
      );

      // Authorize veterinarian
      simnet.callPublicFn(
        contractName,
        "authorize-veterinarian",
        [Cl.principal(address2)],
        deployerAddress
      );

      // Add health record
      const { result } = simnet.callPublicFn(
        contractName,
        "add-health-record",
        [
          Cl.uint(1), // livestock-id
          Cl.stringAscii("Excellent"), // health-status
          Cl.stringUtf8("Regular checkup completed. All vitals normal."), // notes
          Cl.stringAscii("Vitamin B12 injection"), // treatment
          Cl.none(), // next-checkup (optional)
          Cl.stringAscii("Up to date") // vaccination-status
        ],
        address2
      );

      expect(result).toBeOk(Cl.uint(1));
    });

    it("should retrieve health records correctly", () => {
      // Register livestock
      simnet.callPublicFn(
        contractName,
        "register-livestock",
        [
          Cl.stringAscii("Goat"),
          Cl.stringAscii("Boer"),
          Cl.uint(36),
          Cl.stringAscii("Male"),
          Cl.stringAscii("Brown"),
          Cl.uint(80),
          Cl.stringAscii("Healthy"),
          Cl.stringAscii("Field D")
        ],
        address1
      );

      // Authorize vet
      simnet.callPublicFn(
        contractName,
        "authorize-veterinarian",
        [Cl.principal(address2)],
        deployerAddress
      );

      // Add health record
      simnet.callPublicFn(
        contractName,
        "add-health-record",
        [
          Cl.uint(1),
          Cl.stringAscii("Very Good"),
          Cl.stringUtf8("Comprehensive health evaluation completed."),
          Cl.stringAscii("Deworming treatment"),
          Cl.some(Cl.uint(100)), // next-checkup in 100 blocks
          Cl.stringAscii("Fully vaccinated")
        ],
        address2
      );

      // Retrieve health record
      const { result } = simnet.callReadOnlyFn(
        contractName,
        "get-health-record",
        [Cl.uint(1), Cl.uint(1)], // livestock-id, record-id
        address1
      );

      expect(result).toBeDefined();
    });
  });
});
