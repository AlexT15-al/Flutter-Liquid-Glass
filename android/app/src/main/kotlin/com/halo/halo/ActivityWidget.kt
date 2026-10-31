package com.halo.halo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.widget.RemoteViews
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.text.NumberFormat
import java.util.Calendar

/**
 * The home screen widget: today's three rings, and at the larger size their
 * numbers and the steps.
 *
 * The app writes a snapshot of the day whenever it changes ([WidgetChannel]);
 * the widget draws from that, so it costs nothing between updates. A
 * snapshot from an earlier day reads as an empty day.
 */
open class ActivityWidget : AppWidgetProvider() {
    /** The compact pill whatever the size, for [ActivityWidgetCompact]. */
    protected open val compact = false

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) render(context, manager, id, compact)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        render(context, manager, id, compact)
    }

    companion object {
        private const val PREFS = "halo_widget"

        /** Redraws every Halo widget on the home screen. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (id in manager.getAppWidgetIds(ComponentName(context, ActivityWidget::class.java))) {
                render(context, manager, id, compact = false)
            }
            for (id in manager.getAppWidgetIds(
                ComponentName(context, ActivityWidgetCompact::class.java),
            )) {
                render(context, manager, id, compact = true)
            }
        }

        fun save(context: Context, values: Map<*, *>) {
            val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            for ((key, value) in values) {
                if (key is String && value is Number) editor.putFloat(key, value.toFloat())
            }
            editor.putLong("updatedAt", System.currentTimeMillis())
            editor.apply()
        }

        private fun render(
            context: Context,
            manager: AppWidgetManager,
            id: Int,
            compact: Boolean,
        ) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = sameDay(prefs.getLong("updatedAt", 0L))
            fun value(key: String) = if (today) prefs.getFloat(key, 0f) else 0f
            fun goal(key: String, fallback: Float) = prefs.getFloat(key, fallback).coerceAtLeast(1f)

            val move = value("move")
            val exercise = value("exercise")
            val hours = value("activeHours")
            val steps = value("steps")
            val moveGoal = goal("moveGoal", 400f)
            val exerciseGoal = goal("exerciseGoal", 30f)
            val hoursGoal = goal("activeHoursGoal", 10f)

            val dark = (context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val moveColor = Color.parseColor(if (dark) "#FA114F" else "#E5124A")
            val exerciseColor = Color.parseColor(if (dark) "#A6FF00" else "#4A8F00")
            val hoursColor = Color.parseColor(if (dark) "#1EEAEF" else "#0095A8")

            val options = manager.getAppWidgetOptions(id)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
            val small = !compact && minWidth < 200

            val views = RemoteViews(
                context.packageName,
                when {
                    compact -> R.layout.widget_activity_compact
                    small -> R.layout.widget_activity_small
                    else -> R.layout.widget_activity
                },
            )
            val density = context.resources.displayMetrics.density
            views.setImageViewBitmap(
                R.id.widget_rings,
                rings(
                    (if (compact) 58 else if (small) 96 else 112) * density,
                    listOf(
                        move / moveGoal to moveColor,
                        exercise / exerciseGoal to exerciseColor,
                        hours / hoursGoal to hoursColor,
                    ),
                ),
            )
            val number = NumberFormat.getIntegerInstance()
            if (compact) {
                // Bare numbers beside their glyphs, as Samsung Health's own.
                views.setTextViewText(R.id.widget_move, number.format(move.toLong()))
                views.setTextViewText(R.id.widget_exercise, "${exercise.toInt()}")
                views.setTextViewText(R.id.widget_hours, "${hours.toInt()}")
            } else {
                views.setTextViewText(R.id.widget_steps, "${number.format(steps.toLong())} steps")
            }
            if (!small && !compact) {
                views.setTextViewText(
                    R.id.widget_move,
                    "${number.format(move.toLong())}/${number.format(moveGoal.toLong())} KCAL",
                )
                views.setTextColor(R.id.widget_move, moveColor)
                views.setTextViewText(
                    R.id.widget_exercise,
                    "${exercise.toInt()}/${exerciseGoal.toInt()} MIN",
                )
                views.setTextColor(R.id.widget_exercise, exerciseColor)
                views.setTextViewText(
                    R.id.widget_hours,
                    "${hours.toInt()}/${hoursGoal.toInt()} HRS",
                )
                views.setTextColor(R.id.widget_hours, hoursColor)
            }
            val open = PendingIntent.getActivity(
                context,
                10,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            manager.updateAppWidget(id, views)
        }

        private fun sameDay(ms: Long): Boolean {
            if (ms == 0L) return false
            val then = Calendar.getInstance().apply { timeInMillis = ms }
            val now = Calendar.getInstance()
            return then.get(Calendar.YEAR) == now.get(Calendar.YEAR) &&
                then.get(Calendar.DAY_OF_YEAR) == now.get(Calendar.DAY_OF_YEAR)
        }

        /** Three concentric rings, outermost first, each over a faint track. */
        private fun rings(size: Float, rings: List<Pair<Float, Int>>): Bitmap {
            val px = size.toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val stroke = px * 0.11f
            val gap = px * 0.02f
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
            }
            rings.forEachIndexed { i, (progress, color) ->
                val inset = stroke / 2 + i * (stroke + gap)
                val rect = RectF(inset, inset, px - inset, px - inset)
                paint.color = color
                paint.alpha = 56
                canvas.drawArc(rect, 0f, 360f, false, paint)
                paint.alpha = 255
                val sweep = 360f * progress.coerceIn(0f, 1f)
                if (sweep > 0f) canvas.drawArc(rect, -90f, sweep.coerceAtLeast(1f), false, paint)
            }
            return bitmap
        }
    }
}

/** The small pill-shaped widget: rings and three numbers in a row of two cells. */
class ActivityWidgetCompact : ActivityWidget() {
    override val compact = true
}

/** `halo/widget`: the app hands the widget today's numbers. */
object WidgetChannel {
    fun attach(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, "halo/widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val values = call.arguments as? Map<*, *>
                    if (values != null) {
                        ActivityWidget.save(app, values)
                        ActivityWidget.refresh(app)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
