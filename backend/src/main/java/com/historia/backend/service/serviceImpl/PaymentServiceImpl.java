package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.PaymentDto;
import com.historia.backend.entity.Booking;
import com.historia.backend.entity.Payment;
import com.historia.backend.entity.User;
import com.historia.backend.enums.BookingStatus;
import com.historia.backend.enums.PaymentMethod;
import com.historia.backend.enums.PaymentStatus;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.BookingRepository;
import com.historia.backend.repository.PaymentRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.NotificationService;
import com.historia.backend.service.PaymentService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class PaymentServiceImpl implements PaymentService {

    private static final Pattern EXPIRY_PATTERN = Pattern.compile("^(\\d{2})/(\\d{2})$");

    // Mock payment for university project: always succeeds
    // In production, this would connect to a real payment gateway
    private static final boolean MOCK_PAYMENT_SUCCESS = true;

    private final BookingRepository bookingRepository;
    private final PaymentRepository paymentRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public PaymentServiceImpl(
            BookingRepository bookingRepository,
            PaymentRepository paymentRepository,
            UserRepository userRepository,
            NotificationService notificationService) {
        this.bookingRepository = bookingRepository;
        this.paymentRepository = paymentRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Override
    @Transactional
    public PaymentDto.PaymentResponse pay(
            String username,
            Long bookingId,
            PaymentDto.CheckoutRequest request) {

        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new UserException("User not found"));

        Booking booking = bookingRepository
                .findByIdAndTourist(bookingId, tourist)
                .orElseThrow(() -> new UserException("Booking not found"));

        if (booking.getStatus() == BookingStatus.PAID) {
            throw new UserException(
                    "This booking has already been paid for");
        }

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new UserException(
                    "This booking has been cancelled");
        }

        String maskedCardNumber = null;
        String cardHolderName = null;
        boolean forcedFailure = false;

        if (request.method() == PaymentMethod.CARD) {

            String digits = validateCardNumber(request.cardNumber());
            cardHolderName = validateCardHolderName(request.cardHolderName());
            validateExpiry(request.expiryDate());
            validateCvv(request.cvv());

            maskedCardNumber = "**** **** **** " + digits.substring(digits.length() - 4);

            // For testing failures: cards ending in "0000" will fail
            // (only in production mode; for university demo, all succeed)
            if (!MOCK_PAYMENT_SUCCESS) {
                forcedFailure = digits.endsWith("0000");
            }
        }

        // For university project demo: always succeed mock payments
        boolean success = MOCK_PAYMENT_SUCCESS || !forcedFailure;

        Payment payment = Payment.builder()
                .booking(booking)
                .method(request.method())
                .status(success ? PaymentStatus.SUCCESS : PaymentStatus.FAILED)
                .amount(booking.getAmount())
                .currency(booking.getCurrency())
                .maskedCardNumber(maskedCardNumber)
                .cardHolderName(cardHolderName)
                .failureReason(success ? null : "Transaction Timedout")
                .transactionRef(generateTransactionRef())
                .build();

        paymentRepository.save(payment);

        if (success) {
            booking.setStatus(BookingStatus.PAID);
            bookingRepository.save(booking);
        }

        notifyPayment(booking, success, payment.getTransactionRef());

        return toResponse(payment);
    }

    private String validateCardNumber(String cardNumber) {

        String digits = cardNumber == null
                ? ""
                : cardNumber.replaceAll("\\D", "");

        if (digits.length() != 16 || !isValidLuhn(digits)) {
            throw new UserException("Enter a valid 16-digit card number");
        }

        return digits;
    }

    private String validateCardHolderName(String cardHolderName) {

        if (cardHolderName == null || cardHolderName.trim().length() < 3) {
            throw new UserException("Enter the name on the card");
        }

        return cardHolderName.trim();
    }

    private void validateExpiry(String expiryDate) {

        Matcher matcher = EXPIRY_PATTERN.matcher(
                expiryDate == null ? "" : expiryDate);

        if (!matcher.matches()) {
            throw new UserException("Use MM/YY for the expiry date");
        }

        int month = Integer.parseInt(matcher.group(1));
        int year = 2000 + Integer.parseInt(matcher.group(2));

        if (month < 1 || month > 12) {
            throw new UserException("Enter a valid expiry month");
        }

        YearMonth expiry = YearMonth.of(year, month);

        if (expiry.isBefore(YearMonth.from(LocalDate.now()))) {
            throw new UserException("Card has expired");
        }
    }

    private void validateCvv(String cvv) {

        String digits = cvv == null ? "" : cvv.trim();

        if (!digits.matches("\\d{3,4}")) {
            throw new UserException("Enter a valid CVV");
        }
    }

    // Standard Luhn checksum used to catch obviously mistyped card numbers.
    private boolean isValidLuhn(String digits) {

        int sum = 0;
        boolean alternate = false;

        for (int i = digits.length() - 1; i >= 0; i--) {
            int n = digits.charAt(i) - '0';

            if (alternate) {
                n *= 2;
                if (n > 9) {
                    n -= 9;
                }
            }

            sum += n;
            alternate = !alternate;
        }

        return sum % 10 == 0;
    }

    private String generateTransactionRef() {
        return "TXN-" + UUID.randomUUID()
                .toString()
                .replace("-", "")
                .substring(0, 12)
                .toUpperCase();
    }

    private PaymentDto.PaymentResponse toResponse(Payment payment) {
        return new PaymentDto.PaymentResponse(
                payment.getId(),
                payment.getBooking().getId(),
                payment.getMethod(),
                payment.getStatus(),
                payment.getAmount(),
                payment.getCurrency(),
                payment.getFailureReason(),
                payment.getTransactionRef(),
                payment.getCreatedAt());
    }

    private void notifyPayment(
            Booking booking,
            boolean success,
            String transactionRef
    ) {

        String referenceId = booking.getId().toString();
        String type = success ? "PAYMENT_SUCCESS" : "PAYMENT_FAILED";
        String title = success ? "Payment completed" : "Payment failed";
        String message = success
                ? "Payment " + transactionRef + " confirmed for your booking."
                : "Payment could not be completed for your booking.";

        notificationService.notifyUser(
                booking.getTourist(),
                type,
                title,
                message,
                "BOOKING",
                referenceId,
                "/bookings/" + referenceId
        );

        notificationService.notifyUser(
                booking.getGuideProfile().getUser(),
                type,
                title,
                message,
                "BOOKING",
                referenceId,
                "/guide/bookings/" + referenceId
        );
    }
}
