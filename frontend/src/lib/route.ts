import type { RouteLocationNormalizedLoadedGeneric } from 'vue-router'

export function parsePositiveIntegerParam(value: unknown) {
  const rawValue = Array.isArray(value) ? value[0] : value
  const parsed = Number(rawValue)

  return Number.isInteger(parsed) && parsed > 0 ? parsed : null
}

export function positiveIntegerRouteParam(
  route: RouteLocationNormalizedLoadedGeneric,
  paramName: string,
) {
  return parsePositiveIntegerParam(route.params[paramName])
}
