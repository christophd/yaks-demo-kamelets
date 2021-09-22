/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.citrusframework.yaks.mail;

import com.consol.citrus.Citrus;
import com.consol.citrus.TestCaseRunner;
import com.consol.citrus.annotations.CitrusAnnotations;
import com.consol.citrus.annotations.CitrusFramework;
import com.consol.citrus.annotations.CitrusResource;
import com.consol.citrus.context.TestContext;
import com.consol.citrus.mail.model.BodyPart;
import com.consol.citrus.mail.model.MailMarshaller;
import com.consol.citrus.mail.model.MailRequest;
import com.consol.citrus.mail.server.MailServer;
import com.consol.citrus.mail.server.MailServerBuilder;
import com.consol.citrus.message.MessageType;
import com.consol.citrus.message.builder.ObjectMappingPayloadBuilder;
import io.cucumber.java.Before;
import io.cucumber.java.Scenario;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import org.citrusframework.yaks.kubernetes.KubernetesSteps;

import static com.consol.citrus.actions.ReceiveMessageAction.Builder.receive;

public class MailSteps {

	@CitrusResource
    private TestCaseRunner runner;

    @CitrusResource
    private TestContext context;

	@CitrusFramework
	private Citrus citrus;

    private MailServer mailServer;

    private int port = 22222;

    private KubernetesSteps kubernetesSteps;

    @Before
    public void before(Scenario scenario) {
        kubernetesSteps = new KubernetesSteps();
        CitrusAnnotations.injectAll(kubernetesSteps, citrus, context);
        CitrusAnnotations.injectTestRunner(kubernetesSteps, runner);
        kubernetesSteps.before(scenario);
    }

    @Given("^mail server port (\\d++)$")
    public void createMailServer(int port) {
        this.port = port;
    }

    @Given("^start mail server$")
    public void createMailServer() {
        MailMarshaller marshaller = new MailMarshaller();
        marshaller.setType(MessageType.JSON.name());

        mailServer = new MailServerBuilder()
                .port(port)
                .marshaller(marshaller)
                .autoStart(true)
                .build();

        citrus.getCitrusContext().getReferenceResolver().bind("mail-server", mailServer);

        kubernetesSteps.createService("mail-server", 25, port);

        mailServer.initialize();
    }

    @Then("verify mail received")
    public void receiveMail() {
        MailRequest request = new MailRequest();
        request.setFrom("${from}");
        request.setTo("${to}");
        request.setCc("");
        request.setBcc("");
        request.setSubject("${subject}");
        request.setBody(new BodyPart("${message}", "text/plain"));

        runner.run(receive(mailServer)
                .message()
                .body(new ObjectMappingPayloadBuilder(request, mailServer.getMarshaller())));
    }

}
