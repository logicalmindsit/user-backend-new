// =====================================================================
// AWS Lambda Handler for Scheduled Cron Jobs (EventBridge Trigger)
// =====================================================================
// This handler is triggered by AWS EventBridge (CloudWatch Events)
// to run EMI-related cron jobs on a schedule.
//
// Usage: Triggered automatically by EventBridge rule (daily at 10 AM IST)
// =====================================================================

import dotenv from "dotenv";
import connectDB from "./src/DB/db.js";
import {
  processOverdueEmis,
  sendPaymentReminders,
} from "./src/Services/EMI-Service.js";

dotenv.config();

/**
 * Lambda handler for scheduled EMI cron jobs
 * @param {Object} event - EventBridge event object
 * @param {Object} context - Lambda context object
 * @returns {Object} Response object with status and message
 */
export const handler = async (event, context) => {
  console.log("⏰ [CRON-START] EventBridge triggered EMI cron job");
  console.log("📅 [CRON-INFO] Event Time:", event.time);
  console.log("🔍 [CRON-INFO] Event ID:", event.id);

  try {
    // Step 1: Connect to MongoDB database
    console.log("🔌 [DB] Connecting to database...");
    await connectDB();
    console.log("✅ [DB] Database connected successfully");

    // Step 2: Process overdue EMI payments
    // This function checks for overdue EMIs and locks course access if needed
    console.log("📧 [EMI-1] Running processOverdueEmis...");
    await processOverdueEmis();
    console.log("✅ [EMI-1] processOverdueEmis completed");

    // Step 3: Send payment reminder emails
    // This function sends reminder emails to users about upcoming EMI payments
    console.log("📧 [EMI-2] Running sendPaymentReminders...");
    await sendPaymentReminders();
    console.log("✅ [EMI-2] sendPaymentReminders completed");

    console.log("🎉 [CRON-SUCCESS] All EMI cron tasks completed successfully");

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        message: "EMI cron job completed successfully",
        timestamp: new Date().toISOString(),
        tasksCompleted: ["processOverdueEmis", "sendPaymentReminders"],
      }),
    };
  } catch (error) {
    // Log error details for CloudWatch monitoring
    console.error("❌ [CRON-ERROR] Error in EMI cron job:", error.message);
    console.error("📋 [CRON-ERROR] Stack trace:", error.stack);

    // Return error response
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        message: "EMI cron job failed",
        error: error.message,
        timestamp: new Date().toISOString(),
      }),
    };
  }
};
