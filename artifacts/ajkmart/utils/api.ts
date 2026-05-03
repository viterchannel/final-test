const domain = process.env.EXPO_PUBLIC_DOMAIN;
if (!domain) {
  // Always assert — a missing domain makes every API call silently return "".
  // In development this surfaces immediately; in production it surfaces at
  // runtime before any network request is attempted.
  const msg =
    "[API] FATAL: EXPO_PUBLIC_DOMAIN is not set. " +
    "All API calls will fail. Set this environment variable before building.";
  if (__DEV__) {
    throw new Error(msg);
  } else {
    // eslint-disable-next-line no-console
    console.error(msg);
  }
}
export const API_BASE = domain ? `https://${domain}/api` : "";

export function unwrapApiResponse<T = Record<string, unknown>>(json: unknown): T {
  if (json != null && typeof json === "object" && "success" in json && (json as Record<string, unknown>)["success"] === true && "data" in json) {
    return (json as Record<string, unknown>)["data"] as T;
  }
  return json as T;
}
