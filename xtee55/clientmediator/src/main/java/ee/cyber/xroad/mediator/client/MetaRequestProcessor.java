package ee.cyber.xroad.mediator.client;

import java.net.URI;

import javax.servlet.http.HttpServletRequest;

import lombok.RequiredArgsConstructor;
import lombok.Value;
import lombok.extern.slf4j.Slf4j;

import org.apache.commons.io.IOUtils;

import ee.cyber.sdsb.common.CodedException;
import ee.cyber.sdsb.common.util.AsyncHttpSender;
import ee.cyber.sdsb.common.util.MimeTypes;
import ee.cyber.xroad.mediator.MediatorSystemProperties;
import ee.cyber.xroad.mediator.common.AbstractMediatorHandler;
import ee.cyber.xroad.mediator.common.HttpClientManager;
import ee.cyber.xroad.mediator.common.MediatorMessageProcessor;
import ee.cyber.xroad.mediator.common.MediatorRequest;
import ee.cyber.xroad.mediator.common.MediatorResponse;

import static ee.cyber.sdsb.common.ErrorCodes.X_INTERNAL_ERROR;
import static ee.cyber.sdsb.common.metadata.MetadataRequests.*;

@Slf4j
@RequiredArgsConstructor
class MetaRequestProcessor implements MediatorMessageProcessor {

    @Value
    static class MetaRequest {
        private final String param;
        private final String value;
    }

    private static final int SEND_TIMEOUT_SECONDS = 120;

    private static final String PARAM_PRODUCER = "producer";
    private static final String PARAM_URI = "uri";
    private static final String PARAM_V6_META = "v6meta";

    private final MetaRequest metaRequest;
    private final HttpClientManager httpClientManager;

    @Override
    public void process(MediatorRequest request, MediatorResponse response)
            throws Exception {
        log.info("Processing meta request ({} = {})", metaRequest.getParam(),
                metaRequest.getValue());

        try (AsyncHttpSender sender =
                new AsyncHttpSender(httpClientManager.getDefaultHttpClient())) {
            sender.doGet(new URI(getTargetAddress(request, metaRequest)));
            sender.waitForResponse(SEND_TIMEOUT_SECONDS);

            response.setContentType(getResponseContentType(sender),
                    sender.getResponseHeaders());
            IOUtils.copy(sender.getResponseContent(),
                    response.getOutputStream());
        }
    }

    private String getTargetAddress(MediatorRequest request,
            MetaRequest metaRequest) {
        if (PARAM_V6_META.equals(metaRequest.getParam())) {
            String parameters = request.getParameters() != null
                    ? "?" + request.getParameters() : "";
            return MediatorSystemProperties.getSdsbProxyAddress()
                    + metaRequest.getValue() + parameters;
        }

        return getUriProxyAddress(metaRequest);
    }

    static String getUriProxyAddress(MetaRequest request) {
        String uriProxyAddress =
                MediatorSystemProperties.getXroadUriProxyAddress();
        uriProxyAddress += "?" + request.getParam() + "=" + request.getValue();

        return uriProxyAddress;
    }

    static MetaRequest getMetaRequest(String target,
            HttpServletRequest request) {
        if (!AbstractMediatorHandler.isGetRequest(request)) {
            return null;
        }

        if (isV6MetaRequest(target)) {
            return new MetaRequest(PARAM_V6_META, target);
        }

        String uri = request.getParameter(PARAM_URI);
        String producer = request.getParameter(PARAM_PRODUCER);
        if (uri != null) {
            return new MetaRequest(PARAM_URI, uri);
        } else if (producer != null)  {
            return new MetaRequest(PARAM_PRODUCER, producer);
        } else {
            throw new CodedException(X_INTERNAL_ERROR, "Unknown meta request");
        }
    }

    private static boolean isV6MetaRequest(String target) {
        return LIST_CLIENTS.equals(target)
                || LIST_CENTRAL_SERVICES.equals(target)
                || WSDL.equals(target);
    }

    private static String getResponseContentType(AsyncHttpSender sender) {
        if (sender.getResponseContentType() != null) {
            return sender.getResponseContentType();
        }

        return MimeTypes.TEXT_XML;
    }
}