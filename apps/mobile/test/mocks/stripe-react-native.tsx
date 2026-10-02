import type { PropsWithChildren } from "react";
import { vi } from "vitest";

type PaymentSheetResult = { error?: { code: string; message: string } };
export const initPaymentSheetMock = vi.fn(async (): Promise<PaymentSheetResult> => ({}));
export const presentPaymentSheetMock = vi.fn(async (): Promise<PaymentSheetResult> => ({}));

export function StripeProvider({ children }: PropsWithChildren) {
  return <>{children}</>;
}

export function useStripe() {
  return {
    initPaymentSheet: initPaymentSheetMock,
    presentPaymentSheet: presentPaymentSheetMock
  };
}

export const initPaymentSheet = initPaymentSheetMock;
export const presentPaymentSheet = presentPaymentSheetMock;
