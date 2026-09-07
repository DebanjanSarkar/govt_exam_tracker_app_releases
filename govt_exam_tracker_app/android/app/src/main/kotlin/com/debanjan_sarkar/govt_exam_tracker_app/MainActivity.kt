package com.debanjan_sarkar.govt_exam_tracker_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.apache.poi.ss.usermodel.*
import org.apache.poi.ss.util.CellRangeAddressList
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.debanjan_sarkar.govt_exam_tracker_app/excel"

    override fun onCreate(savedInstanceState: Bundle?) {
        System.setProperty("javax.xml.stream.XMLInputFactory", "com.fasterxml.aalto.stax.InputFactoryImpl")
        System.setProperty("javax.xml.stream.XMLOutputFactory", "com.fasterxml.aalto.stax.OutputFactoryImpl")
        System.setProperty("javax.xml.stream.XMLEventFactory", "com.fasterxml.aalto.stax.EventFactoryImpl")
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "generateNativeExcel") {
                val jsonPayload = call.argument<String>("payload")
                if (jsonPayload != null) {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val filePath = createExcelFile(jsonPayload)
                            withContext(Dispatchers.Main) {
                                result.success(filePath)
                            }
                        } catch (oom: OutOfMemoryError) {
                            withContext(Dispatchers.Main) {
                                result.error("OOM_ERROR", "Phone memory limit reached", null)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("EXCEL_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "No payload provided", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createExcelFile(jsonPayload: String): String {
        val jsonObj = JSONObject(jsonPayload)
        val columns = jsonObj.getJSONArray("columns")
        val sheetsData = jsonObj.getJSONObject("sheets")

        val workbook = XSSFWorkbook()
        val creationHelper = workbook.creationHelper

        // 1. STYLES
        val headerStyle = workbook.createCellStyle().apply {
            fillForegroundColor = IndexedColors.DARK_BLUE.index
            fillPattern = FillPatternType.SOLID_FOREGROUND
            val font = workbook.createFont().apply {
                color = IndexedColors.WHITE.index
                bold = true
            }
            setFont(font)
            alignment = HorizontalAlignment.CENTER
            verticalAlignment = VerticalAlignment.CENTER
        }

        val wrapStyle = workbook.createCellStyle().apply {
            wrapText = true
            verticalAlignment = VerticalAlignment.CENTER
        }

        // The Strict Date Style (Triggers Calendar Popups in Mobile Excel/Sheets)
        val dateStyle = workbook.createCellStyle().apply {
            wrapText = true
            verticalAlignment = VerticalAlignment.CENTER
            alignment = HorizontalAlignment.CENTER
            dataFormat = creationHelper.createDataFormat().getFormat("dd-MMM-yyyy")
        }

        val statusOptions = arrayOf("Not Applied", "Applied", "Admit Card Out", "Exam Given", "Result Out", "Archived")
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)

        val keys = sheetsData.keys()
        while (keys.hasNext()) {
            val year = keys.next()
            val sheet = workbook.createSheet(year)
            val rows = sheetsData.getJSONArray(year)

            // We give the user exactly 50 pre-formatted empty rows to add new exams into
            val maxRow = rows.length() + 50

            val headerRow = sheet.createRow(0)
            var statusColIndex = -1
            val dateColIndices = mutableListOf<Int>()

            // 2. HEADERS & COLUMN TRACKING
            for (i in 0 until columns.length()) {
                val colName = columns.getString(i)
                val cell = headerRow.createCell(i)
                cell.setCellValue(colName)
                cell.cellStyle = headerStyle

                if (colName == "Status") statusColIndex = i
                if (colName.contains("Date")) dateColIndices.add(i)

                val width = if (colName == "Notes" || colName == "Additional Info" || colName == "Portal URL") 15000 else 6000
                sheet.setColumnWidth(i, width)
            }

            // 3. POPULATE DATA & PRE-FORMAT EMPTY CELLS
            for (r in 0 until maxRow) {
                val row = sheet.createRow(r + 1)
                val hasData = r < rows.length()
                val rowObj = if (hasData) rows.getJSONArray(r) else null

                for (c in 0 until columns.length()) {
                    val cell = row.createCell(c)
                    val isDateCol = dateColIndices.contains(c)

                    if (hasData && rowObj != null) {
                        val value = rowObj.getString(c)
                        if (isDateCol && value.isNotEmpty()) {
                            try {
                                val parsedDate = sdf.parse(value)
                                cell.setCellValue(parsedDate)
                                cell.cellStyle = dateStyle
                            } catch (e: Exception) {
                                cell.setCellValue(value)
                                cell.cellStyle = wrapStyle
                            }
                        } else {
                            cell.setCellValue(value)
                            cell.cellStyle = if (isDateCol) dateStyle else wrapStyle
                        }
                    } else {
                        // THE MAGIC: Explicitly style the empty cells!
                        // This makes clicking an empty date cell open a calendar widget!
                        cell.cellStyle = if (isDateCol) dateStyle else wrapStyle
                    }
                }
            }

            // 4. DROPDOWNS & CONDITIONAL FORMATTING (Applied to all 50 empty rows too!)
            if (statusColIndex != -1) {
                val validationHelper = sheet.dataValidationHelper
                val constraint = validationHelper.createExplicitListConstraint(statusOptions)
                val addressList = CellRangeAddressList(1, maxRow, statusColIndex, statusColIndex)
                val validation = validationHelper.createValidation(constraint, addressList)
                validation.showErrorBox = true
                sheet.addValidationData(validation)

                val sheetCF = sheet.sheetConditionalFormatting
                fun addColorRule(statusStr: String, colorIndex: Short) {
                    val rule = sheetCF.createConditionalFormattingRule(ComparisonOperator.EQUAL, "\"$statusStr\"")
                    val pattern = rule.createPatternFormatting()
                    pattern.fillBackgroundColor = colorIndex
                    pattern.fillPattern = org.apache.poi.ss.usermodel.PatternFormatting.SOLID_FOREGROUND
                    sheetCF.addConditionalFormatting(arrayOf(org.apache.poi.ss.util.CellRangeAddress(1, maxRow, statusColIndex, statusColIndex)), rule)
                }

                addColorRule("Applied", IndexedColors.LIGHT_CORNFLOWER_BLUE.index)
                addColorRule("Result Out", IndexedColors.LIGHT_GREEN.index)
                addColorRule("Exam Given", IndexedColors.LAVENDER.index)
                addColorRule("Admit Card Out", IndexedColors.LIGHT_YELLOW.index)
            }
        }

        val dir = File(context.cacheDir, "exports")
        if (!dir.exists()) dir.mkdirs()

        val file = File(dir, "Govt_Exams_Export_${System.currentTimeMillis()}.xlsx")
        val out = FileOutputStream(file)
        workbook.write(out)
        out.close()
        workbook.close()

        return file.absolutePath
    }
}