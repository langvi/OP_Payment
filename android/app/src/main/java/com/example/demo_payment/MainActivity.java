package com.example.demo_payment;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.Observer;

import org.jetbrains.annotations.NotNull;

import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private final String Channel = "tuanchaubooking/onepay_gateway";
    private static final String MERCHANT_APP_SCHEME = "merchantappscheme";
    private static final String CREATE_URL = "create_url";
    private static final String OPEN_APP_BANK = "open_app_bank";
    private static final String ONE_PAY_PAYMENT = "one_pay_payment";
    private static final String BASE_URL = "https://mtf.onepay.vn/paygate/vpcpay.op?";
    /**
     * merchant app scheme deep link, same config in AndroidManifest.xml
     * <data android:scheme="merchantappscheme" />
     * provided by OnePAY
     */
    public static final String PREFIX_RETURN_URL = MERCHANT_APP_SCHEME + "://onepay/";
    /**
     * Unique value for each merchant provided by OnePAY
     */
    private static final String ACCESS_CODE = "6BEB2546";
    /**
     * Unique value for each merchant provided by OnePAY
     */
    private static final String MERCHANT = "TESTONEPAY";
    /**
     * Unique value for each merchant provided by OnePAY
     */
    private static final String SECURE_SECRET = "6D0870CDE5F24F34F3915FB0045120DB";


    private static final int REQUEST_CODE_PAYMENT = 0x4;
    private MutableLiveData<String> resultLiveData;
    MethodChannel.Result result;
    Boolean isSendResult = false;

    @Override
    public void configureFlutterEngine(@NonNull @NotNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), Channel);

        MethodChannel.MethodCallHandler callHandler = (MethodCall call, MethodChannel.Result result) -> {
            this.result = result;
            if (call.method.equals(CREATE_URL)) {
                String amount = call.argument("amount");
                OpPaymentActivity.start(
                        MainActivity.this, createUrl(amount), REQUEST_CODE_PAYMENT);
//                String url = createUrl(amount);
//                setupLiveData();
//                gotoBankAppByUriIntent(url);
//                result.success(url);
            } else if (call.method.equals(OPEN_APP_BANK)) {
                String url = call.argument("url");
//                setupLiveData();
//                gotoBankAppByUriIntent(url);
            }
        };
        channel.setMethodCallHandler(callHandler);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 200 && resultCode == Activity.RESULT_OK) {
            if (data != null && data.getData() != null) {
                Map<String, String> mapResponse = OpUtils.splitQuery(data.getData().toString());
                String vpcTxnResponseCode = mapResponse.get("vpc_TxnResponseCode");
                String vpcMessage = mapResponse.get("vpc_Message");
                String vpcAmount = mapResponse.get("vpc_Amount");
                String vpcSecureHash = mapResponse.get("vpc_SecureHash");
                String vpcTransactionNo = mapResponse.get("vpc_TransactionNo");
                if (vpcTxnResponseCode != null
                        && vpcTxnResponseCode.equals("0")) {
//                    if(result!=null){
                    Log.d("Payment:", "Payment success");
                    result.success("0");
//                    }
                } else {
                    result.success("-1");
                    Log.d("Payment:", "Payment failed");
                }
            }
        }

    }

    private void gotoBankAppByUriIntent(String url) {
        try {
            Intent intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(intent);
        } catch (URISyntaxException e) {
            e.printStackTrace();
        } catch (ActivityNotFoundException e) {

        }
    }

    private MutableLiveData<String> getResultLiveData() {
        if (resultLiveData == null) {
            resultLiveData = new MutableLiveData<>();
        }
        return resultLiveData;
    }

    //
    private void setupLiveData() {
        // Create the observer which updates the UI.
        final Observer<String> resultObserver =
                new Observer<String>() {
                    @Override
                    public void onChanged(@Nullable final String url) {
                        if (isSendResult) {
                            Map<String, String> mapResponse = OpUtils.splitQuery(url);
                            String responseCode = mapResponse.get("vpc_TxnResponseCode");
                            if (responseCode != null && responseCode.equals("0")) { // payment success
                                result.success("0");
                            } else { // payment failed
                                result.success("-1");
                            }
                        } else {
                            isSendResult = false;
                        }

                    }
                };
        getResultLiveData().observe(this, resultObserver);
    }

    private String createUrl(String amount) {
        Map<String, String> mapParams = new HashMap<>();
        // Version module of payment gateway, default is “2”
        mapParams.put("vpc_Version", "2");

        // Payment Function, value is “pay”
        mapParams.put("vpc_Command", "pay");

        // Unique value for each merchant provided by OnePAY
        mapParams.put("vpc_AccessCode", ACCESS_CODE);

        // Unique value for each merchant provided by OnePAY
        mapParams.put("vpc_Merchant", MERCHANT);

        // Language is used on the payment site Vietnamese: vn, English: en
        String language = Locale.getDefault().getLanguage();
        if ("vi".equalsIgnoreCase(language)) {
            mapParams.put("vpc_Locale", "vn");
        } else {
            mapParams.put("vpc_Locale", "en");
        }


        // Merchant’s URL Website for redirect response
        mapParams.put("vpc_ReturnURL", PREFIX_RETURN_URL);

        // A unique value is created by merchant  then send to OnePAY, System.currentTimeMillis for
        // testing
        mapParams.put("vpc_MerchTxnRef", String.valueOf(System.currentTimeMillis()));
        // Order infomation, it could be an order number or brief description of order
        mapParams.put("vpc_OrderInfo", "OP test");

        // The amount of the transaction, this value does not have decimal comma. Add “00” before
        // redirect to payment gateway. If transaction amount is VND 25,000 then the amount is
        // 2500000
        mapParams.put("vpc_Amount", amount + "00");

        // IP address of customer – Do not set a fixed IP
        mapParams.put("vpc_TicketNo", "10.2.20.1");

        // The link of website before redirecting to OnePAY
        mapParams.put("AgainLink", "https://mtf.onepay.vn");

        // Title of payment gateway is shown on the cardholder’s browser
        mapParams.put("Title", "test");

        // Payment Currency, default is VND
        mapParams.put("vpc_Currency", "VND");

        // theme
        //mapParams.put("vpc_Theme", "general");

        String vpc_SecureHash = OpUtils.genSecureHash(mapParams, SECURE_SECRET);
        // Hash encryption is for merchant to authenticate and ensure data integrity.
        mapParams.put("vpc_SecureHash", vpc_SecureHash);
        String paramsUrl = OpUtils.appendQueryFields(mapParams);
        return BASE_URL + paramsUrl;
    }
}
