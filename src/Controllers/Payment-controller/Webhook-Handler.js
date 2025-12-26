//Controllers/Payment-controller/Webhook-Handler.js
import crypto from "crypto";
import dotenv from "dotenv";
import Payment from "../../Models/Payment-Model/Payment-Model.js";
import EMIPlan from "../../Models/Emi-Plan/Emi-Plan-Model.js";
import User from "../../Models/User-Model/User-Model.js";
import Course from "../../Models/Course-Model/Course-model.js";
import { createEmiPlan } from "../Payment-controller/Payment-Controller.js";
import {
  updateEmiAfterPayment,
  createEmiPaymentRecord,
} from "../../Services/EMI-Utils.js";

dotenv.config();

// Webhook signature verification
const verifyWebhookSignature = (body, signature) => {
  const expectedSignature = crypto
    .createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(JSON.stringify(body))
    .digest("hex");

  return crypto.timingSafeEqual(
    Buffer.from(expectedSignature, "hex"),
    Buffer.from(signature, "hex")
  );
};

// Main webhook handler
export const handleRazorpayWebhook = async (req, res) => {
  try {
    const signature = req.headers["x-razorpay-signature"];

    if (!signature) {
      return res.status(400).json({
        success: false,
        message: "Missing webhook signature",
      });
    }

    // Verify webhook signature
    if (!verifyWebhookSignature(req.body, signature)) {
      return res.status(400).json({
        success: false,
        message: "Invalid webhook signature",
      });
    }

    const { event, payload } = req.body;

    switch (event) {
      case "payment.captured":
        await handlePaymentCaptured(payload.payment.entity);
        break;

      case "payment.failed":
        await handlePaymentFailed(payload.payment.entity);
        break;

      case "order.paid":
        await handleOrderPaid(payload.order.entity);
        break;

      default:
        //console.log(`Unhandled webhook event: ${event}`);
        return res.status(200).json({
          success: true,
          message: `Webhook event ${event} received but not processed`,
          event: event
        });
    }

     return res.status(200).json({
      success: true,
      message: "Webhook processed successfully",
      event: event,
      data: result
    });
  } catch (error) {
    console.error("Webhook processing error:", error);
    res.status(500).json({
      success: false,
      message: "Webhook processing failed",
    });
  }
};

// Handle successful payment capture
const handlePaymentCaptured = async (paymentData) => {
  try {
    const {
      id: razorpayPaymentId,
      order_id: razorpayOrderId,
      amount,
      method,
    } = paymentData;

    // Find the payment record
    const payment = await Payment.findOne({
      razorpayOrderId,
      paymentStatus: "pending",
    });

    if (!payment) {
      //console.error("Payment record not found for order:", razorpayOrderId);
      return {
        success: false,
        message: "Payment record not found",
        orderId: razorpayOrderId
      };
    }

    // Update payment status
    payment.paymentStatus = "completed";
    payment.razorpayPaymentId = razorpayPaymentId;
    payment.paymentMethod = method.toUpperCase();
    await payment.save();

    // Handle course enrollment based on payment type
    // if (payment.paymentType === "emi") {
    //   await handleEmiEnrollment(payment);
    // } else {
    //   await handleFullPaymentEnrollment(payment);
    // }

    // Handle course enrollment based on payment type
    let enrollmentResult;
    if (payment.paymentType === "emi") {
      console.log("Processing EMI enrollment");
      enrollmentResult = await handleEmiEnrollment(payment);
    } else {
      console.log("Processing full payment enrollment");
      enrollmentResult = await handleFullPaymentEnrollment(payment);
    }

    //console.log(`Payment captured successfully: ${razorpayPaymentId}`);
    return {
      success: true,
      paymentId: razorpayPaymentId,
      orderId: razorpayOrderId,
      paymentType: payment.paymentType,
      enrollment: enrollmentResult
    };

  } catch (error) {
    console.error("Error handling payment capture:", error);
     return {
      success: false,
      message: "Failed to handle payment capture",
      error: error.message
    };
  }
};

// Handle EMI enrollment after payment
const handleEmiEnrollment = async (payment) => {
  try {
    const [user, course] = await Promise.all([
      User.findById(payment.userId),
      Course.findById(payment.courseId),
    ]);

  
    if (!user) {
      //console.error(`User not found with ID: ${payment.userId}`);
      throw new Error("User not found");
    }

    if (!course) {
      //console.error(`Course not found with ID: ${payment.courseId}`);
      throw new Error("Course not found");
    }

    // Create EMI plan (you'll need to export this function from Payment-Controller.js)
    const emiPlan = await createEmiPlan(
      payment.userId,
      payment.courseId,
      course,
      user,
      payment.emiDueDay,
      {
        monthlyAmount: payment.amount,
        totalAmount: course.price.finalPrice,
        months: Math.ceil(course.price.finalPrice / payment.amount),
      }
    );

    //console.log(`EMI plan created for payment: ${payment._id}`);
     return {
      success: true,
      emiPlanId: emiPlan._id,
      userId: payment.userId,
      courseId: payment.courseId
    };

  } catch (error) {
    console.error("Error handling EMI enrollment:", error);
      return {
      success: false,
      message: "Failed to create EMI enrollment",
      error: error.message
    };
  }
};

// Handle full payment enrollment
const handleFullPaymentEnrollment = async (payment) => {
  try {
    // Update user's enrolled courses
    await User.findByIdAndUpdate(payment.userId, {
      $addToSet: {
        enrolledCourses: {
          course: payment.courseId,
          coursename: payment.courseName,
          accessStatus: "active",
        },
      },
    });

    // Update course enrollment count
    await Course.findByIdAndUpdate(payment.courseId, {
      $inc: { studentEnrollmentCount: 1 },
    });

    console.log(
      `Full payment enrollment completed for payment: ${payment._id}`
    );
  } catch (error) {
    console.error("Error handling full payment enrollment:", error);
  }
};

// Handle failed payments
const handlePaymentFailed = async (paymentData) => {
  try {
    const {
      order_id: razorpayOrderId,
      error_code,
      error_description,
    } = paymentData;

    // Update payment status to failed
    await Payment.findOneAndUpdate(
      { razorpayOrderId },
      {
        paymentStatus: "failed",
        errorCode: error_code,
        errorDescription: error_description,
      }
    );

    console.log(`Payment failed for order: ${razorpayOrderId}`);
    return {
      success: true,
      orderId: razorpayOrderId,
      errorCode: error_code,
      errorDescription: error_description,
      paymentId: updatedPayment._id
    };
  } catch (error) {
    console.error("Error handling payment failure:", error);
     return {
      success: false,
      message: "Failed to handle payment failure",
      error: error.message
    };
  }
};

// Handle order paid event
const handleOrderPaid = async (orderData) => {
    // console.log("Starting order paid event handling");
    // console.log("Order data:", JSON.stringify(orderData, null, 2));

  try {
    const { id: razorpayOrderId, amount_paid } = orderData;

    //console.log(`Order paid confirmation: ${razorpayOrderId}, Amount: ${amount_paid}`);

    // Additional verification can be done here
    const payment = await Payment.findOne({ razorpayOrderId });
    
    if (payment) {
      //console.log(`Found associated payment record: ${payment._id}`);
      return {
        success: true,
        orderId: razorpayOrderId,
        amountPaid: amount_paid,
        paymentId: payment._id,
        paymentStatus: payment.paymentStatus
      };
    } else {
      //console.log(`No payment record found for order: ${razorpayOrderId}`);
      return {
        success: true,
        orderId: razorpayOrderId,
        amountPaid: amount_paid,
        message: "Order paid but no payment record found"
      };
    }

  } catch (error) {
    // console.error("Error handling order paid:", error);
    // console.error("Error stack:", error.stack);
    return {
      success: false,
      message: "Failed to handle order paid event",
      error: error.message
    };
  }
};

export default {
  handleRazorpayWebhook,
};
