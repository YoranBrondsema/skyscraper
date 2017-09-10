defmodule Skyscraper.Skyscanner do
  def get_itineraries(from, to, depart, return) do
    IO.puts "Processing #{from} -> #{to}\t#{Date.to_string depart} -> #{Date.to_string return}"

    response = make_request(
      get_params(from, to, depart, return)
    )

    case response do
      { :ok, %{ body: body } } ->
        process_response_body(
          body, from, to, depart, return
        )
      { :error, reason } ->
        IO.inspect "Error when making request."
        IO.inspect reason
        nil
    end
  end

  defp process_response_body(body, from, to, depart, return) do
    %{
      "itineraries" => itineraries,
      "legs" => legs
    } = body
        |> :zlib.gunzip
        |> Poison.decode!

    itineraries
    |> add_leg_information(legs)
    |> Enum.map(
      fn (itinerary) ->
        %{
          from: from,
          to: to,
          depart: depart,
          return: return,
          price: Skyscraper.Itinerary.cheapest_price(itinerary),
          duration_depart: Skyscraper.Itinerary.duration_depart(itinerary),
          duration_return: Skyscraper.Itinerary.duration_return(itinerary)
        }
      end
    )
  end

  defp add_leg_information(itineraries, legs) do
    itineraries
    |> Enum.map(
      fn (itinerary) ->
        %{ "leg_ids" => leg_ids } = itinerary

        Map.put_new(
          itinerary,
          "legs",
          find_legs(legs, leg_ids)
        )
      end
    )
  end

  defp find_legs(legs, leg_ids) do
    legs
    |> Enum.filter(
      fn (%{ "id" => id }) ->
        Enum.member?(leg_ids, id)
      end
    )
  end

  defp make_request(params) do
    HTTPoison.post(
      get_url(),
      params,
      get_headers()
    )
  end

  defp get_url do
    %URI{
      host: "www.skyscanner.com",
      scheme: "https",
      path: "/dataservices/flights/pricing/v3.0/search",
      query: URI.encode_query(%{
        geo_schema: "skyscanner",
        carrier_schema: "skyscanner",
        response_include: "query"
        # response_include: "query,deeplink,segment,stats,fqs,pqs,_flights_availability"
      })
    }
    |> URI.to_string
  end

  defp get_headers do
    [
      "Host": "www.skyscanner.com",
      "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:55.0) Gecko/20100101 Firefox/55.0",
      "Accept": "application/json, text/javascript, */*; q=0.01",
      "Accept-Language": "en-US,en;q=0.5",
      "Accept-Encoding": "gzip, deflate, br",
      "Content-Type": "application/json; charset=utf-8",
      "X-Skyscanner-ChannelId": "website",
      "X-Distil-Ajax": "azezcavtdrrxfqrtbw",
      "X-Skyscanner-MixPanelId": "a3c43640-f52b-4fb6-a3e0-a408f6cb1fb9",
      "X-Skyscanner-TrackId": "null",
      "X-Skyscanner-DeviceDetection-IsMobile": "false",
      "X-Skyscanner-DeviceDetection-IsTablet": "false",
      "X-Skyscanner-ViewId": "a3c43640-f52b-4fb6-a3e0-a408f6cb1fb9",
      "X-Skyscanner-Traveller-Context": "null",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://www.skyscanner.com/transport/flights/brus/ista/171227/airfares-from-brussels-to-istanbul-in-december-2017.html?adults=1&children=0&adultsv2=1&childrenv2=&infants=0&cabinclass=economy&rtn=0&preferdirects=false&outboundaltsenabled=false&inboundaltsenabled=false&ref=home",
      "Content-Length": "298",
      "Cookie": "D_IID=00E62F4E-2AE5-37FE-A1DE-EC9372572AD2; D_UID=F99D8B23-B1FE-332D-AA22-CC447E3A7EF8; D_ZID=10B819E0-DA1F-3DA1-AFD3-BB89B4DAACE1; D_ZUID=C74E06BC-A86F-340B-8E8B-119DDD61C1EC; D_HID=F72E0532-A878-3A6D-8E1E-9D46823B0596; D_SID=196.52.84.21:EagWUMvpNskHP0cqdJ2p7xd2h9ygvCEvUZD2CoKXPnI; X-Mapping-fpkkgdlh=A8D5A033741BFF9CAE39929682086C6C; scanner=adults:::1&originalAdults:::1&adultsV2:::1&children:::0&originalChildren:::0&infants:::0&originalInfants:::0&charttype:::1&rtn:::false&preferDirects:::false&includeOnePlusStops:::true&cabinclass:::Economy&tripType:::OneWayTrip&ncr:::false&lang:::EN&currency:::USD&outboundAlts:::false&inboundAlts:::false&from:::BRUS&to:::ISTA&oym:::1712&oday:::27&legs:::BRUS%7C2017-12-27%7CISTA&usrplace:::US&wy:::0&iym:::&iday:::&fromCy:::BE&toCy:::TR; ssculture=locale:::en-US&currency:::USD&market:::US; ssab=STARK_iOS_UseWalletAssetServiceForLoyaltyCards_V6:::on&Hfe_PricePerNight_V2:::b&FlightsHeroImage_CA_11_07_2016_36_20_V2:::b&GDT2195_RolloutMicroserviceIntegration_V4:::b&FlightsHeroStraplineUpper_ConfidencemessageforIN_06_09_2016_38_13_V1:::a&FlightsHeroStraplineUpper_ConfidencemessageforIN_06_09_2016_42_06_V2:::a&AAExperiment_V8:::a&ADS_Android_MigrationPopupExperiment_V10:::a&MonthViewSpringCleanBackground_EnableMVspringcleaninpre_prod_22_06_2017_34_23_V1:::a&AVGS_Android_TopDealsCaret_V1:::off&TestFeature1_Useexperiment_02_11_2016_25_28_V1:::a&TCS_PriceAlertsFilters_V5:::b&Car_NewGrouping_V6:::b&HNT_Android_TID_Exponential_Backoff_V5:::on&VES_iOS_ItineraryLogging_V1:::on&Americas_ConfidenceMessagingv3_V6:::b&TAME_US___Thanksgiving_inline_banners_V2:::a&INS1606_IndicativeResultsView_V1:::b&INS1964_MVProfileChange_V2:::b&FlightsHeroImage_US_19_07_2016_10_08_V2:::b&AfsKeywordsSelection_V1:::b&AFS_DayView_Firebase_NPS_V10:::off&Hsc_MexicanToAS2_V4:::b&FlightsAndroidProdTest_V1:::a&Car_AWS_API_V24:::b&WPT_OcFooter_V4:::b&TAME_IN_DayView_Promocode_Experiment_V2:::a&RAC_DateShiftErrorLogging_V2:::on&TCS_AccountSettings_MaxPrice_V4:::showmaxprice&glu_springCleanRollout_V2:::a&VES_iOS_Unified_Experiment_Analytics_V7:::on&FlightsHeroImage_US_25_07_2016_40_13_V2:::b&TCP2770RunFlightHeroimagelomocompressiontest_V1:::a&TAME_promote_map_V2:::b&INS1846_PerDayDirectness_V1:::b&INS1887_ConsumeStoredPricesOnBV_V9:::b&Enable_OneSignal_Integration_EnableforTWmarket_31_05_2017_46_13_V3:::b&FlightsiOSProdTest_V2:::b&Car_AATest_V4:::a&UtidTravellerIdentity_V11:::b&RPW_PopularDestination_V4:::b&AEP_SEOPageUniversalLinksExperiment_TR_V3:::on&GDT1693_MonthViewSpringClean_V13:::b&Ads_UseESIAds_V1:::b&Fss_springclean_datepicker_V5:::b&TAME_SG___Inspirational_Image_Experiment_V3:::a&Enable_OneSignal_Integration_EnableforUKmarket_31_05_2017_47_09_V3:::b&ABE_iOS_HotelsAutosuggestV2_V3:::on&HFE_hotels_statements_reorder_V2:::c&Enable_OneSignal_Integration_EnableforBRmarket_03_08_2017_28_13_V3:::b&Fss_NewSearchControls_V6:::c&BPK150_NewPrimaryButtonDesign_V4:::b&Enable_OneSignal_Integration_EnableforUSmarket_31_05_2017_42_08_V3:::b&AVGS_iOS_ScreenshotSharing_ShortenerVariation_V1:::d&Hsc_ChildrenAgeView_V10:::b&fps_mbmd_V10:::b&ShowOcCookieBanner_Enablewithexperiment_11_07_2017_40_09_V5:::b&Apps_ErrorLogging_Android_V5:::on&WebApps_FacebookPixelUpgrade_V5:::b&INS1683_BrowseUpdating_V6:::b&Enable_OneSignal_Integration_EnableforAUmarket_31_05_2017_44_00_V3:::b&scaffold_wireup_dont_delete_V1:::b&Car_GooglePlaces_V10:::b&Enable_OneSignal_Integration_EnableforHKmarket_31_05_2017_45_27_V3:::b&Ads_QualityOfAdsHideButton_V5:::b&Enable_OneSignal_Integration_EnableforAEmarket_03_08_2017_24_13_V2:::b&DEAL_Default_To_Two_Guests_V3:::b&Hfe_OfficialPartner_It2_V2:::b&Trex_flexDays_V46:::a&Apps_ErrorLogging_iOS_V6:::on&Ads_ShowIntentMedia_V1:::b&Trex_generalSearchV2_V7:::a&HNT_iOS_NewTidNetworkLayer_V5:::off&fbw_native_remove_progress_bar_V1:::b&Enable_OneSignal_Integration_EnableforCAmarket_31_05_2017_43_08_V3:::b&Enable_OneSignal_Integration_EnableforIEmarket_04_08_2017_12_43_V2:::b&GDT1276_TimelineToTopOfHomepage_V2:::b&FlightsHeroImage_GG_27_06_2016_57_51_V2:::a&Enable_OneSignal_Integration_EnableforPLmarket_03_08_2017_31_24_V2:::b&TurnFeatureTests:::on; ssassociate=; abgroup=65474137; X-Mapping-rrsqbjcb=xsfzfc7gj3fhyzj1idgotbviqx2wmz9j",
      "DNT": "1",
      "Connection": "keep-alive",
      "Pragma": "no-cache",
      "Cache-Control": "no-cache"
    ]
  end

  defp get_params(from, to, depart, return) do
    Poison.encode!(%{
      "market" => "US",
      "currency" => "USD",
      "locale" => "en-US",
      "cabin_class" => "economy",
      "prefer_directs" => false,
      "trip_type" => "return",
      "legs" => [
        %{
          "origin" => from,
          "destination" => to,
          "date" => Date.to_string(depart),
          "return_date" => Date.to_string(return)
        }
      ],
      "adults" => 1,
      "child_ages" => [],
      "options" => %{
        "include_unpriced_itineraries" => true,
        "include_mixed_booking_options" => true
      }
    })
  end
end
