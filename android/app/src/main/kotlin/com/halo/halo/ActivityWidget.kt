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

/** The kinds of Halo widget on the home screen. */
enum class WidgetStyle {
    /** Rings with their numbers; the rings alone when narrow. */
    FULL,

    /** A pill: rings, Move, Exercise and Active Hours. */
    RINGS_PILL,

    /** A pill: rings, steps, energy and exercise minutes. */
    STATS_PILL,

    /** A pill: today's steps against the goal. */
    STEPS_PILL,
}

/**
 * The home screen widgets: today's rings and numbers in four shapes.
 *
 * The app writes a snapshot of the day whenever it changes ([WidgetChannel]);
 * the widgets draw from that, so they cost nothing between updates. A
 * snapshot from an earlier day reads as an empty day.
 */
open class ActivityWidget : AppWidgetProvider() {
    protected open val style = WidgetStyle.FULL

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) render(context, manager, id, style)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        render(context, manager, id, style)
    }

    companion object {
        private const val PREFS = "halo_widget"

        private val providers = listOf(
            ActivityWidget::class.java to WidgetStyle.FULL,
            ActivityWidgetCompact::class.java to WidgetStyle.RINGS_PILL,
            ActivityWidgetStats::class.java to WidgetStyle.STATS_PILL,
            ActivityWidgetSteps::class.java to WidgetStyle.STEPS_PILL,
        )

        /** Redraws every Halo widget on the home screen. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for ((provider, style) in providers) {
                for (id in manager.getAppWidgetIds(ComponentName(context, provider))) {
                    render(context, manager, id, style)
                }
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
            style: WidgetStyle,
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
            val stepsGoal = goal("stepsGoal", 10000f)

            val dark = (context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val moveColor = Color.parseColor(if (dark) "#FA114F" else "#E5124A")
            val exerciseColor = Color.parseColor(if (dark) "#A6FF00" else "#4A8F00")
            val hoursColor = Color.parseColor(if (dark) "#1EEAEF" else "#0095A8")
            val ringValues = listOf(
                move / moveGoal to moveColor,
                exercise / exerciseGoal to exerciseColor,
                hours / hoursGoal to hoursColor,
            )

            val minWidth = manager.getAppWidgetOptions(id)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
            val small = style == WidgetStyle.FULL && minWidth < 200
            val density = context.resources.displayMetrics.density
            val number = NumberFormat.getIntegerInstance()

            val views = RemoteViews(
                context.packageName,
                when (style) {
                    WidgetStyle.RINGS_PILL -> R.layout.widget_activity_compact
                    WidgetStyle.STATS_PILL -> R.layout.widget_activity_stats
                    WidgetStyle.STEPS_PILL -> R.layout.widget_steps
                    WidgetStyle.FULL ->
                        if (small) R.layout.widget_activity_small else R.layout.widget_activity
                },
            )

            when (style) {
                WidgetStyle.STEPS_PILL -> {
                    views.setTextViewText(R.id.widget_steps, number.format(steps.toLong()))
                    views.setTextViewText(
                        R.id.widget_steps_goal,
                        "of ${number.format(stepsGoal.toLong())} steps",
                    )
                    views.setProgressBar(
                        R.id.widget_steps_progress,
                        1000,
                        (steps / stepsGoal * 1000).toInt().coerceIn(0, 1000),
                        false,
                    )
                }
                WidgetStyle.STATS_PILL -> {
                    views.setImageViewBitmap(R.id.widget_rings, rings(58 * density, ringValues))
                    views.setTextViewText(R.id.widget_steps, number.format(steps.toLong()))
                    views.setTextViewText(R.id.widget_move, number.format(move.toLong()))
                    views.setTextViewText(R.id.widget_exercise, "${exercise.toInt()}")
                }
                WidgetStyle.RINGS_PILL -> {
                    views.setImageViewBitmap(R.id.widget_rings, rings(58 * density, ringValues))
                    // Bare numbers beside their glyphs, as Samsung Health's own.
                    views.setTextViewText(R.id.widget_move, number.format(move.toLong()))
                    views.setTextViewText(R.id.widget_exercise, "${exercise.toInt()}")
                    views.setTextViewText(R.id.widget_hours, "${hours.toInt()}")
                }
                WidgetStyle.FULL -> {
                    views.setImageViewBitmap(
                        R.id.widget_rings,
                        rings((if (small) 96 else 112) * density, ringValues),
                    )
                    views.setTextViewText(
                        R.id.widget_steps,
                        "${number.format(steps.toLong())} steps",
                    )
                    if (!small) {
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
                }
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

/** A pill of two cells: rings, Move, Exercise and Active Hours. */
class ActivityWidgetCompact : ActivityWidget() {
    override val style = WidgetStyle.RINGS_PILL
}

/** A pill of two cells: rings, steps, energy and exercise minutes. */
class ActivityWidgetStats : ActivityWidget() {
    override val style = WidgetStyle.STATS_PILL
}

/** A pill of two cells: today's steps and how far to the goal. */
class ActivityWidgetSteps : ActivityWidget() {
    override val style = WidgetStyle.STEPS_PILL
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
