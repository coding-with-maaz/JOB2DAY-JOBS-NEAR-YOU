package com.maazkhan07.jobsinquwait

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ListTileNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.native_ad_layout, null) as NativeAdView

        // Bind MediaView for video/image
        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        adView.bodyView = adView.findViewById<TextView>(R.id.ad_body)

        // Set headline and body
        (adView.headlineView as TextView).text = nativeAd.headline
        nativeAd.body?.let {
            (adView.bodyView as TextView).text = it
        } ?: run {
            adView.bodyView?.visibility = View.GONE
        }

        // Set media content (image only, no video)
        nativeAd.mediaContent?.let { mediaContent ->
            if (mediaContent.hasVideoContent()) {
                // Hide the media view if it's a video
                adView.mediaView?.visibility = View.GONE
            } else {
                // Show the image
                adView.mediaView?.setMediaContent(mediaContent)
                adView.mediaView?.visibility = View.VISIBLE
            }
        }
        // (No video controller logic needed)

        adView.setNativeAd(nativeAd)
        return adView
    }
} 