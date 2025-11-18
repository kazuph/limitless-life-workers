import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export const cn = (...inputs: unknown[]) => twMerge(clsx(inputs))

export const toLocaleTime = (value?: string | null) => {
  if (!value) return '--:--'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '--:--'
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

export const formatDateLabel = (value?: string | null) => {
  if (!value) return 'Unknown date'
  const formatter = new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    weekday: 'short'
  })
  return formatter.format(new Date(value))
}
