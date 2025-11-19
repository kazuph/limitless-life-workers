import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'
import { useId as useReactId } from 'react'

export const cn = (...inputs: unknown[]) => twMerge(clsx(inputs))

export const useId = (deterministicId?: string) => {
  const nonDeterministicId = useReactId()
  return deterministicId || nonDeterministicId
}

export const toLocaleTime = (value?: string | null) => {
  if (!value) return '--:--'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '--:--'
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

export const formatDateLabel = (value?: string | null) => {
  if (!value) return 'Unknown date'
  const date = new Date(value)

  // Format: 2025-11-18 (月)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const weekday = date.toLocaleDateString('ja-JP', { weekday: 'short' })

  return `${year}-${month}-${day} (${weekday})`
}
