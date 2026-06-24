import { Controller, Get, Query } from '@nestjs/common';
import {
  ETHIOPIA_REGIONS,
  ETHIOPIA_REGIONS_AND_CITIES,
  getCitiesForRegion,
} from '../constants/ethiopia-regions';
import { Public } from '../decorators/public.decorator';

@Public()
@Controller('locations')
export class LocationsController {
  @Get('regions')
  listRegions(): string[] {
    return ETHIOPIA_REGIONS;
  }

  @Get('regions-cities')
  listRegionsAndCities(): Record<string, string[]> {
    return ETHIOPIA_REGIONS_AND_CITIES;
  }

  @Get('cities')
  listCities(): string[] {
    return Object.values(ETHIOPIA_REGIONS_AND_CITIES).flat();
  }

  @Get('cities-for-region')
  citiesForRegion(@Query('region') region?: string): string[] {
    return region ? getCitiesForRegion(region) : [];
  }
}