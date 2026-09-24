import { BadRequestException } from '@nestjs/common';

export function parsePositiveInteger(
  value: unknown,
  fieldName: string,
): number {
  const parsed = typeof value === 'number' ? value : Number(value);

  if (!Number.isSafeInteger(parsed) || parsed <= 0) {
    throw new BadRequestException(`${fieldName} must be a positive integer`);
  }

  return parsed;
}
