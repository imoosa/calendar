// Place under: android/app/src/main/kotlin/<your/package/path>/TodayWidgetProvider.kt
// Requires the home_widget package's HomeWidgetBackgroundIntent/receiver already
// registered by `flutter pub add home_widget` + its platform setup.
//
// This is a Glance-based widget (androidx.glance). Add to app/build.gradle:
//   implementation "androidx.glance:glance-appwidget:1.1.0"

package com.yourcompany.interfaithcalendar

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetPlugin
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color as ComposeColor

class TodayWidgetProvider : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TodayGlanceWidget()
}

class TodayGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // home_widget stores the values saved from Dart via
        // HomeWidget.saveWidgetData() in this SharedPreferences file.
        val prefs = HomeWidgetPlugin.getData(context)

        val nativeLabel = prefs.getString("native_label", "") ?: ""
        val fajr = prefs.getString("fajr", "--:--") ?: "--:--"
        val asr = prefs.getString("asr", "--:--") ?: "--:--"
        val maghrib = prefs.getString("maghrib", "--:--") ?: "--:--"
        val isha = prefs.getString("isha", "--:--") ?: "--:--"
        val eventTitle = prefs.getString("event_title", "") ?: ""
        val eventCount = prefs.getString("event_count", "0") ?: "0"

        provideContent {
            WidgetContent(nativeLabel, fajr, asr, maghrib, isha, eventTitle, eventCount)
        }
    }

    @Composable
    private fun WidgetContent(
        nativeLabel: String,
        fajr: String,
        asr: String,
        maghrib: String,
        isha: String,
        eventTitle: String,
        eventCount: String,
    ) {
        // Transparent by default — this is the real transparency the browser
        // widget could never get. Swap ColorProvider.Companion.Transparent for
        // a solid color if you want a card background instead.
        Column(
            modifier = androidx.glance.GlanceModifier
                .fillMaxWidth()
                .padding(12.dp)
                .background(ComposeColor.Transparent)
        ) {
            Text(
                text = nativeLabel,
                style = TextStyle(fontWeight = FontWeight.Bold, color = ColorProvider(ComposeColor(0xFFB5121B)))
            )
            Row(modifier = androidx.glance.GlanceModifier.padding(top = 6.dp)) {
                Text(text = "Fajr $fajr   Asr $asr")
            }
            Row {
                Text(text = "Maghrib $maghrib   Isha $isha")
            }
            if (eventCount != "0") {
                Text(
                    text = if (eventCount == "1") eventTitle else "$eventTitle +${eventCount.toInt() - 1} more",
                    modifier = androidx.glance.GlanceModifier.padding(top = 6.dp)
                )
            } else {
                Text(text = "No events today")
            }
        }
    }
}
